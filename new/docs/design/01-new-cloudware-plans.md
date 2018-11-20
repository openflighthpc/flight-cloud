
# Goal

Cloudware should be a cluster-aware, but as non-prescriptive and flexible as
possible, tool for launching, terminating, and managing cloud nodes defined in
(cloud platform-specific) templates across multiple cloud platforms.

# Requirements and implementation overview

## Supported cloud platfroms

Cloudware will initially support all its features for the AWS and Azure cloud
platforms; adding support for new platforms will require Cloudware code changes
but these should be as localized as possible.

## Data model

Cloudware will need to persist data about what it has deployed and is managing
across command runs; it makes sense to use a relational database for this for
the data integrity guarantees this will provide, and we will use PostgreSQL for
this both for consistency with most of our other products, and for all other
reasons that we normally make this choice.

The planned initial Cloudware data model can be seen at
https://github.com/alces-software/cloudware/blob/95100ef86485934c9604ee4d0582bb33922f56be/new/docs/erd.pdf,
and a brief overview of this is given below.

- A `Deployment` represents one `template` (in whatever format this means for
  the platform), successfully deployed on a given `platform`, and uniquely
  identifiable on that platform by the given `name` (along with the currently
  configured platform access credentials). The `name` will be the actual name
  of the deployed stack/resource group for AWS/Azure, but may be whatever
  identifier uniquely identifies this `Deployment` for additional cloud
  platforms supported in future.

  Note that, though not required by the cloud platforms (as, of course, AWS
  knows nothing about what you have deployed to Azure), we will enforce at the
  Cloudware-level the uniqueness of `Deployment` `name`s across all platforms.
  This will have the advantage of allowing us to uniquely identify
  `Deployment`s by `name` throughout Cloudware, both in commands operating on
  `Deployment`s and when templating, and places only a minor restriction on the
  templates which can be launched by Cloudware.

  Also note that, for consistency across clouds and in order to support a
  simple method of accessing all records when templating, `Deployment`, `Node`,
  and `Output` `name`s will all be validated to be valid Ruby identifiers (i.e.
  `my_node01` is valid, `my-node01` is not). This restriction can be
  reconsidered if you think this is too limiting.

- Each `Deployment` produces zero-to-many `Output`s, a set of name-value pairs
  produced by deploying this template on the cloud platform. These can have
  arbitrary `name`s, and all produced `Output`s will be saved in the database,
  however certain `Output`s being produced will have special handling and cause
  `Node` entries to be created.

- Every `Output` may belong to a `Node` (or may just be an output of the
  `Deployment` unrelated to a `Node`), and every `Node` will have one-to-many
  `Output`s. Every `Output` of the form `${node_name}__${output_name}` will be
  picked up and cause a `Node` with `name` `$node_name` to be created, if this
  does not already exist, and will be associated with this `Node`.

  While none will be strictly required, some of these `Node` `Output`s with a
  particular `$output_name` may be depended upon by other parts of Cloudware to
  perform further actions related to a `Node` (and at least one `Output` with
  any `name` will be needed for every `Node`, for Cloudware to be aware that it
  has deployed this `Node`). For instance, a `${node_name}__id` `Output` will
  be required to perform future actions to interact with the `Node` on the
  cloud platform (like the `power` commands, described below), while a
  `${node_name}__ip` action may later be used to provide a `console` command to
  easily SSH to a `Node`.

  Note the double-underscore separating the two parts of the name of these
  special `Node` `Output`s: this was chosen as (I believe) underscores should
  always be valid in output names for all platforms we will initially/may later
  want to support, and we may want to use single underscores to provide normal
  separation within output names.  Also note that, since a single node can only
  be deployed to a single location at a time, each `Node`'s `name` uniquely
  identifies this `Node` within the database.

- This database will represent the state of everything (that we want to track)
  deployed by the current Cloudware installation at the current time. If
  needed, we can later switch to using soft deletes if we want to retain a
  history of all past things deployed as well.

## Simple templating system

Cloudware will use templates to deploy to each of the cloud platforms that it
supports. Cloudware will not be prescriptive about how these templates should
be created; ultimately in practise however it is likely that
[Underware](https://github.com/alces-software/underware) (following various
incoming changes to this) will often be used to create these templates.

As such, most complex aspects of creating Cloudware templates will be beyond
the scope of Cloudware itself, however Cloudware will need some simple
templating functionality in order to support using the `value`s of `Output`s
from previous `Deployment`s in later `Deployment`s. Two initial considerations
for choosing this templating system are as follows:

1. The Cloudware templating system should be able to unobtrusively live
   alongside the Underware templating system. For example, it should be
   possible for a template to be rendered by Underware to automate complex
   aspects of constructing the template like looping through various values,
   having various conditional sections depending on the current Underware
   configuration, rendering partial templates within the main template etc.,
   and then for this Underware-rendered template to also be rendered by
   Cloudware, without special consideration needing to be made in either of
   these stages to support the other stage (like escaping ERB tags etc.).

2. The Cloudware templating system should be intentionally simplistic and just
   needs to support the insertion of `Output` values in otherwise static
   templates  - anything more complex than this is beyond the scope of
   Cloudware (and is the responsibility of Underware or however else templates
   are being created).

Given these requirements, [Mustache](https://github.com/mustache/mustache) may
be a good choice for Cloudware templates, as this is intentionally simple and
should be able to independently live alongside Underware's ERB templates if
needed.

Initially, I believe the following should be sufficient features within
Cloudware's templating system (and attempting anything beyond this should be an
error):

- `{{ deployment.SOME_DEPLOYMENT.outputs.SOME_OUTPUT }}`: inserts the value of
  the `Output` with `name` `SOME_OUTPUT`, for `Deployment` with `name`
  `SOME_DEPLOYMENT`, in the template. If the `Deployment` or the `Output`
  cannot be found then this should be an error.

- `{{ node.SOME_NODE.outputs.SOME_OUTPUT }}`: similarly, this inserts the value
  of the given `Output` for the `Node` with `name` `SOME_NODE` in the template,
  and an error should occur if either of these cannot be found.

  One distinction between this and the `Deployment` method of inserting an
  `Output` is that the `Node` output should be specified without the
  `${node_name}__` prefix, i.e.  `{{ node.gpunode01.outputs.ip }}` will insert
  the `value` of the `Output` with `name` `gpunode01__ip`, obtained when the
  `gpunode01` `Node` was deployed.

## `cloud deploy PLATFORM NAME TEMPLATE` command

This command will deploy template at (relative or absolute) path `TEMPLATE`, on
given cloud `PLATFORM`, and with given `NAME` (aside: in practise `PLATFORM`
will be able to be treated, and may be implemented, more like a sub-command
than an argument, and we will be able to provide completion and help for these
commands as we will know all possible values up-front).

The brief planned operation of this command is as follows:

1. `TEMPLATE` will be resolved as a file path, either relative to the current
   working directory or as an absolute path, and loaded.

2. The loaded template will be rendered as specified in the previous section;
   if an error occurs when doing this then this will be displayed and the
   deploy aborted.

3. Cloudware will attempt to deploy the rendered template, with given `NAME`,
   to given `PLATFORM`, and give some feedback about what it is doing.

4. If this deployment fails, as much information as possible about the
   underlying issue will be dumped and Cloudware will exit with a failure.

5. If this deployment succeeds, Cloudware will obtain all outputs produced by
   the deployment and save:
   - a `Deployment` representing the deployment itself, with the rendered
     template as the `template` field (which, though inessential for the
     initial required Cloudware features, will be done as this should be
     straightforward, and it may be useful both for debugging and so an
     identical deploy can be repeated at some future time if needed);
   - an `Output` for each produced output;
   - for each output with name in the form `${node_name}__${output_name}`, a
     corresponding `Node` with this name will also be created  and associated
     with the `Output`.

6. On success, it would also be useful to output a brief summary of any/all
   newly launched `Node`s, and all `Output`s produced by deploying the
   template.

## `cloud destroy NAME` command

This command will essentially be the reverse of the `cloud deploy` command, and
will find and destroy the specified `Deployment` on the Cloud platform this was
deployed on, and clean up the corresponding database entries locally. This is
planned to operate as follows:

1. Find the specified `Deployment` using the given `NAME`, erroring if this
   cannot be found.

2. Attempt to destroy this `Deployment` as appropriate for the Cloud platform
   it is deployed on, with some feedback about what Cloudware is doing.

3. Display informative error if this fails.

4. If this succeeds, delete from the database this `Deployment` and all records
   related to this (any associated `Output`s, and through these any associated
   `Node`s).

## `cloud power` commands

These commands will function similarly to the current Cloudware's `power`
commands, and unlike `deploy`/`destroy` these will operate on the individual
`Node` level (or at least on groups of nodes) rather than the `Deployment`
level. These commands will consist of:

- `cloud power on NAME [-g]`
- `cloud power off NAME [-g]`
- `cloud power status NAME [-g]`

These commands will each operate in a similar way:

1. Attempt to resolve `NAME`, either as a `Node` (the default; resolve by
   attempting to load this from database) or a group of `Node`s (if `-g` option
   passed, by using `nodeattr` and then looking in the database for these
   `Node`s.
   - Aside: it shouldn't be a requirement of Cloudware for any `Node` to be
     part of a configured genders group, or even for `nodeattr` to be an
     available command; providing `-g` options just provides a convenient way
     to operate on groups of `Node`s if a user has independently configured
     these. If `nodeattr` isn't available or a group cannot be resolved, then
     an informative error on this issue should just be output and the command
     aborted.

2. If all specified `Node`s cannot be found, this is an error, however if just
   some `Node`s cannot be found then carry on, and these `Node`s should be
   displayed as 'unlaunched'.

3. Attempt to perform the given action on the resolved `Node`s.

4. Output table of node names and power statuses (or 'unlaunched' if a node has
   not been launched), and give appropriate exit code given requested action:
   - `power on` - give error exit code if unable to power some of the launched
     nodes on;
   - `power off` - give error exit code if unable to power some of the launched
     nodes off;
   - `power status` - give error exit code if unable to retrieve status of some
     of the launched nodes.

   Note that, in order to perform each of these actions for a node on a
   platform, it will likely be required to resolve the ID output of a `Node`,
   i.e. to access the `${node_name}__id` `Output`. If this cannot be resolved,
   then this should be treated similarly to any other reason that the action
   might be unable to be performed and this error should be displayed in the
   table.

## Deployment inspection commands

It would be useful for Cloudware to provide commands at different levels to
inspect the state of what it has currently deployed and it is managing. Some
suggested initial commands to do this are as follows (`list` commands will have
a row shown per `Deployment` or `Node`, with a column for each field, while
`show` commands will have two columns, with the left for the name of the field
and the right for the value):

- `deployment list` - display a table of all current `Deployment`s, with some
  brief overview information. Suggested initial fields:
  - `Deployment` `name`;
  - `Deployment` `platform`;
  - time `Deployment` was deployed;
  - short, horizontal list of names of any `Node`s created by `Deployment`;
  - count of `Output`s created by `Deployment`.

- `deployment show NAME` - display table with more information on single
  `Deployment`. Suggested initial fields:
  - `Deployment` `name`;
  - `Deployment` `platform`;
  - time `Deployment` was deployed;
  - vertical list of names of `Node`s created by `Deployment` - possibly these
    could have brief additional information displayed alongside, such as the
    unique ID for each node (if this `Output` was produced);
  - nested table of all `Output`s created by `Deployment`.

- `node list` - display table of all current `Node`s deployed by Cloudware,
  with some brief overview information. Suggested initial fields:
   - `Node` name;
   - `Deployment` `platform`;
   - time `Node` was deployed;
   - `name` of `Deployment` `Node` is part of;
   - `platform` of `Deployment` `Node` is part of;
   - count of `Output`s associated with `Node`;

- `node show NAME` - display table with more information on single
  `Node`. Suggested initial fields:
  - `Node` `name`;
  - `Deployment` `platform`;
  - time `Node` was deployed;
  - `name` of `Deployment` `Node` is part of;
  - `platform` of `Deployment` `Node` is part of;
  - nested table of all `Node` `Output`s, with `name`s shown in short form
    (e.g. `id` rather than `${node_name}__id`).

# Consideration of future extensions

1. `${node_name}__ip` outputs could be picked up for `Node`s and used to
   support a `cloud console $node_name` command, to allow easy SSH access to a
   deployed node by just specifying an output in this format in the template.

2. This design should make it possible to support CloudFormation changesets, or
   other cloud equivalents, as we may want to do this in future. The exact way
   this should be implemented will depend on the exact future requirements we
   have, but a changeset being applied to a `Deployment` could be represented
   by updating the `Deployment`s record and associated `Output`s/`Node`s, or
   alternatively by using a new table associated with the `Deployment`s table.

# Implementation notes

## `PlatformAdapter` interface

As part of supporting multiple cloud platforms in Cloudware, while allowing new
cloud platforms to be added with minimal code changes, we should confine our
interactions with each cloud platform to a single adapter class which conforms
to a consistent API specified by us.

This will also allow Cloudware to be unconcerned about the particular details
of our interactions with individual clouds outside of these classes, and give
us a single place to stub our cloud interactions in tests (which we should do
in most tests, outside of tests for these classes directly and end-to-end
integration tests).

The suggested initial interface for these adapter classes is as follows:

```ruby
class PlatformAdapter
  # Notes:
  #
  # - Initially all actions within an instance of this class will be
  # synchronous, i.e. Cloudware will wait while a `power_status` action is being
  # performed before it can display the results (although internally results
  # may be retrieved in parallel if this is possible/useful). Later we can
  # consider how to support displaying results in progress, so e.g. partial
  # results for `power_status` can be displayed while further results are still
  # being retrieved
  #
  # - All methods in these classes will error descriptively with generic errors
  # which can be displayed by Cloudware if the action fails.

  def deploy(template:, name:)
    # Returns hash of outputs: `{ name => value }`
  end

  def destroy(name:)
    # Return value unspecified/unimportant
  end

  def power_on(machine_ids:)
    # Return hash of machine `id`s to power status of each machine (here and
    # for functions below, exactly how to handle power status is still to be
    # determined, but will be something representing `On | Off |
    # maybe_other_things`)
  end

  def power_off(machine_ids:)
    # Return hash of machine `id`s to power status of each machine
  end

  def power_status(machine_ids:)
    # Return hash of machine `id`s to power status of each machine
  end
end
```
