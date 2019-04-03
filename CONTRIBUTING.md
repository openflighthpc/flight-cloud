# Contributing to Flight Cloud

:+1::tada: Thanks for taking the time to contribute! :tada::+1:

You want to contribute to Flight Cloud? Welcome! Please read this
document to understand what you can do:

 * [Code of Conduct](#code-of-conduct)
 * [Help Others](#help-others)
 * [Analyse Issues](#analyse-issues)
 * [Report an Issue](#report-an-issue)
 * [Contribute Changes](#contribute-changes)

When contributing to this repository, please first discuss the change
you wish to make via a Github issue or a post on the [OpenFlight
Community site](https://community.openflighthpc.org).

Please note we have a [code of conduct](CODE_OF_CONDUCT.md), please
follow it in all your interactions with the project.

## Code of Conduct

This project and everyone participating in it is governed by the
[OpenFlight Code of Conduct](CODE_OF_CONDUCT.md). By participating,
you are expected to uphold this code. Please report unacceptable
behaviour to [help@openflighthpc.org](mailto:help@openflighthpc.org).

## Help Others

You can help Flight Cloud by helping others who use it and need support.

## Analyse Issues

Analysing issue reports can be a lot of effort. Any help is welcome!
Go to [the GitHub issue tracker](https://github.com/openflighthpc/flight-cloud/issues?state=open)
and find an open issue which needs additional work or a bugfix
(e.g. issues labeled with "help wanted" or "bug").

Additional work could include any further information, or a gist, or
it might be a hint that helps understanding the issue. Maybe you can
even find and [contribute](#contribute-changes) a bugfix?

## Report an Issue

If you find a bug - behaviour of Flight Cloud code or documentation
contradicting your expectation - you are welcome to report it. We can
only handle well-reported, actual bugs, so please follow the
guidelines below.

Once you have familiarised with the guidelines, you can go to the
[GitHub issue tracker for Flight Cloud](https://github.com/openflighthpc/flight-cloud/issues/new)
to report the issue.

### Quick Checklist for Bug Reports

Issue report checklist:

 * Real, current bug
 * No duplicate
 * Reproducible
 * Good summary
 * Well-documented
 * Minimal example

### Issue handling process

When an issue is reported, a committer will look at it and either
confirm it as a real issue, close it if it is not an issue, or ask for
more details.

An issue that is about a real bug is closed as soon as the fix is committed.

### Reporting Security Issues

If you find a security issue, please act responsibly and report it not
in the public issue tracker, but directly to us, so we can fix it
before it can be exploited.  Please send the related information to
[security@openflighthpc.org](mailto:security@openflighthpc.org).

### Issue Reporting Disclaimer

We want to improve the quality of Flight Cloud and good bug reports are
welcome! However, our capacity is limited, thus we reserve the right
to close or to not process bug reports with insufficient detail in
favour of those which are very cleanly documented and easy to
reproduce. Even though we would like to solve each well-documented
issue, there is always the chance that it will not happen - remember:
Flight Cloud is Open Source and comes without warranty.

Bug report analysis support is very welcome! (e.g. pre-analysis or
proposing solutions)

## Contribute Changes

You are welcome to contribute code, content or documentation to
Flight Cloud in order to fix bugs or to implement new features.

There are three important things to know:

1. You must be aware of the Eclipse Public License 2.0 (which
   describes contributions) and **agree to the Contributors License
   Agreement**. This is common practice in all major Open Source
   projects.
2. **Not all proposed contributions can be accepted**. Some features
   may e.g. just fit a third-party add-on better. The change must fit
   the overall direction of Flight Cloud and really improve it. The more
   effort you invest, the better you should clarify in advance whether
   the contribution fits: the best way would be to just open an issue
   to discuss the feature you plan to implement (make it clear you
   intend to contribute).

### Contributor License Agreement

When you contribute (code, documentation, or anything else), you have
to be aware that your contribution is covered by the same [Eclipse
Public License 2.0](https://opensource.org/licenses/EPL-2.0) that is
applied to Flight Cloud itself.

In particular you need to agree to the Contributor License Agreement,
which can be [found
here](https://www.clahub.com/agreements/openflighthpc/flight-cloud). This
applies to all contributors, including those contributing on behalf of
a company. If you agree to its content, you simply have to click on
the link posted by the CLA assistant available on the pull
request. Click it to check the CLA, then accept it on the following
screen if you agree to it. CLA assistant will save this decision for
upcoming contributions and will notify you if there is any change to
the CLA in the meantime.

## Pull Request Process

1. Make sure the change would be welcome (e.g. a bugfix or a useful
   feature); best do so by proposing it in a GitHub issue.
2. Fork, then clone the repo.
3. Make your changes ([see below](#making-changes)) and commit.
4. In the commit message:
    - Describe the problem you fix with this change.
    - Describe the effect that this change has from a user's point of
      view. App crashes and lockups are pretty convincing for example,
      but not all bugs are that obvious and should be mentioned in the
      text.
    - Describe the technical details of what you changed. It is
      important to describe the change in a most understandable way so
      the reviewer is able to verify that the code is behaving as you
      intend it to.
5. If your change fixes an issue reported at GitHub, add the following
   line to the commit message:
    - `Fixes #(issueNumber)`
    - Do NOT add a colon after "Fixes" - this prevents automatic closing.
6. Open a pull request!
7. Follow the link posted by the CLA assistant to your pull request
   and accept it, as described in detail above.
8. Wait for our code review and approval, possibly enhancing your
   change on request.
    - Note that the Flight Cloud developers also have their regular
      duties, so depending on the required effort for reviewing,
      testing and clarification this may take a while.
9. Once the change has been approved we will inform you in a comment.
10. We will close the pull request; feel free to delete the now
    obsolete branch.

## Making Changes

1. Create a topic branch from where you want to base your work.
    * This is usually the `master` branch.
    * Only target release branches if you are certain your fix must be
      on that branch.
    * To quickly create a topic branch based on master, run `git
      checkout -b fix/master/my_contribution master`. Please avoid
      working directly on the `master` branch.
2. Make commits of logical and atomic units.
3. Check for unnecessary whitespace with `git diff --check` before
   committing.

## Attribution

These contribution guidelines are adapted from
[various](https://github.com/cla-assistant/cla-assistant/blob/master/CONTRIBUTING.md)
[previous](https://github.com/puppetlabs/puppet/blob/master/CONTRIBUTING.md)
[contribution](https://gist.github.com/PurpleBooth/b24679402957c63ec426)
[guideline](https://github.com/atom/atom/blob/master/CONTRIBUTING.md)
documents from other projects hosted on Github. Our thanks to the
respective authors for making contributing to Open Source projects a
more streamlined and efficient process!
