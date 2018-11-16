
# Development

## To set up development environment

1. Install `docker` and `docker-compose` in some way, will depend on your
   particular environment.

2. Run:
  ```bash
  # Start all Docker containers - run this, and leave running, each time you
  # start developing.
  docker-compose up

  # Create development/test databases; cannot be automatically done in previous
  # step as depends on `cloudware` and `db` containers already existing and
  # being able to communicate.
  docker-compose exec cloudware rake db:setup
  ```

# To run common development tasks

Various development tasks are available via Rake and can be viewed with `rake
-T`. Most of these are intended to be run on the Cloudware Docker container;
the `docker:` tasks provide a convenient way to access and run various
commands, including other Rake tasks (via `rake docker:bash`), on this
container.
