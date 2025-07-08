# Development environment setup

To use the provided [dev container](.devcontainer/devcontainer.json), install the following tools:
- [Podman](https://podman.io/docs/installation)
    - The podman machine must use [rootful execution](https://docs.podman.io/en/stable/markdown/podman-machine-set.1.html#rootful). This is necessary for podman-in-podman to work.

        ``` shell
        podman machine stop
        podman machine set --rootful
        podman machine start
        ```

    - Enable cgroup v2 if it is not already enabled on your machine.
        - For Windows, create the file *"%UserProfile%\\.wslconfig"* with the following content [(see this stackoverflow question.)](https://stackoverflow.com/questions/73021599/how-to-enable-cgroup-v2-in-wsl2):

            ``` text
            [wsl2]
            kernelCommandLine = cgroup_no_v1=all
            ```

        - For Linux, see this [GitHub discussion](https://github.com/containers/podman/issues/23539).
- Podman compose
    - Install [Python](https://www.python.org/downloads/).

        During the install, select the option to create environment variables.

    - Install podman compose.

        ``` shell
        pip install podman-compose
        ```

Ensure that your editor is using `podman` and `podman-compose` when using the dev container and not `docker` or `docker-compose`.
- For VS Code with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension, set the following settings under *Extensions > Dev Containers > User*:
    - *Dev > Containers: Docker Compose Path* = podman-compose
    - *Dev > Continaers: Docker Path* = podman
    - If you have dotfiles you want to use in the container that are stored in a git repository, you can set these settings too:
        - *Dotfiles: Repository*
        - *Dotfiles: Target Path*
        - *Dotfiles: Install Command*

# Dev container installed tools

The following tools are installed in the dev container:
- [Sqitch](https://sqitch.org/)

    All PostgreSQL source code and unit tests are added using Sqitch, a database migration tool. Each database change is contained in a *deploy* file. A *verify* file exists for each *deploy* file that verifies that the expected changes to the database were made after executing the *deploy* file. A *revert* undoes the changes made by a *deploy* file.

- [Podman](https://podman.io/)

    In order to debug database objects, it is necessary to deploy databases to contain them. Podman is installed inside the container to host databases for debugging.

# Developing

## Create database instances for debugging

Use the script [db/container_utils.sh](db/container_utils.sh) to create, destroy, start, stop, or shell into a database server. The server is a podman container that runs inside the dev container, and it can also be accessed from the host using whichever database client you prefer (e.g. [DBeaver](https://dbeaver.io/)) on port 5432. When a server is created, the superuser login role `postgres` and a non-superuser login role `nonadmin` are created, both with the password `password`. Only the non-superuser login role should be necessary, since pgTAP_fixture does not require superuser privileges. See [db/sqitch](db/sqitch) to see exactly how the database server is provisioned.

``` shell
# Examples:
# Create the PostgreSQL server with PostgreSQL version 17.
./db/container_utils.sh create 17
# Destroy the PostgreSQL server with PostgreSQL version 17.
./db/container_utils.sh destroy 17
# Start the PostgreSQL server with PostgreSQL version 17.
./db/container_utils.sh start 17
# Stop the PostgreSQL server with PostgreSQL version 17.
./db/container_utils.sh stop 17
# Open an interactive bash shell into the PostgreSQL server with PostgreSQL version 17.
./db/container_utils.sh shell 17
```

## Using sqitch

Source code, tests, (and database provisioning) are organized into sqitch projects. New objects are added using `sqitch add`, changes are made to previously tagged and released objects using `sqitch rework`, and new versions are tagged using `sqitch tag`.

When developing, changes can be deployed to and reverted in a database for debugging using `sqitch deploy` and `sqitch revert`. Be diligent to revert a change in a database before modifying a change or a plan, especially when modifying a *revert* or *verify* script or reordering changes in a plan. Worst case scenario, if you really goof things up, you can use [db/container_utils.sh](db/container_utils.sh) to `destroy` and `create` the database again.

Never modify sql files that have been tagged and released. Use `sqitch rework` to create a new change to modify the tagged change.

See the [sqitch documentation](https://sqitch.org/docs/) for guidance on how to use sqitch.

## Developing tests

PostgreSQL objects are tested using [pgTAP](https://pgtap.org/). There some functions for which testing is tricky, being as pgTAP_fixture is dependent on pgTAP, but not many. Each test must be created in the `unit_test` schema. Each test function should have a description that is a shall statement, i.e. a requirement, that describes what functionality the test is verifying.

If a test needs to stub a function that shouldn't be called or mock a function that the test needs to control behavior of, then rename that function and recreate it within the body of the test.

``` sql
-- Example:
create function unit_test.my_test()
returns setof text language plpgsql as $$
declare test_description text := 'My function shall produce certain output under certain conditions.';
begin
    -- Stub or mock a function.
    alter function _function_to_mock_or_stub()
    rename to _function_to_mock_or_stub___original;
    create function _function_to_mock_or_stub()
    returns boolean language plpgsql as $mock$
    begin
        -- Leave empty for a stub, or add statements for a mock.
    end; $mock$;

    -- Return test results.
    return query select tap.ok(true, test_description);
end; $$;
```

Tests can be deployed to the *upgrade_debug* database or the *install_debug* database, depending on whether the upgrade scripts or the fresh install scripts should be tested. Deploy using `sqitch deploy` and specifying a target name, e.g. `upgrade17` for the *upgrade_debug* database on the PostgreSQL 17 server. The defined target names are listed in [test/sqitch/sqitch.conf](test/sqitch/sqitch.conf).
``` shell
# Example:
cd test/sqitch
# Deploy all changes to the upgrade_debug database in the PostgreSQL 17 server.
sqitch deploy upgrade17
```

Tests can be executed using [test/run_tests.sh](test/run_tests.sh) and passing it the PostgreSQL version, the name of the database where the tests are, and a regular expression that matches the names of all tests in the `unit_test` schema. The results of a test are stored in [test/results](test/results).
``` shell
# Example:
# Run all tests whose function names begin with "test_" in the upgrade_debug database in the PostgreSQL 17 server.
./test/run_tests.sh 17 upgrade_debug ^test_
```

## Developing source

The source code contains two sqitch plans: *install.plan* and *upgrade.plan*. *upgrade.plan* contains sql files that will be used to upgrade or downgrade pgTAP_fixture to different versions. *install.plan* contains sql files that will be used for a fresh install of the latest pgTAP_fixture version. Many sql files are in both of these plans, hence they are named *shared.sql*. When a new sql object is added to pgTAP_fixture, it should be named *shared.sql* and be `sqitch add`-ed to both plans. If a sql object in a file in a tagged version is modified, such as by an ALTER statement or DROP and CREATE statements, then its sql file should be `sqitch rework`-ed in *upgrade.plan* and a separate file should be `sqitch add`-ed to *install.plan*. Name the reworked file and the new file to reflect the plans they are included in.

To debug, use `sqitch deploy` to deploy *upgrade.plan* or *install.plan* to a database. The targets that can be deployed are listed in [src/sqitch/sqitch.conf](src/sqitch/sqitch.conf).
``` shell
# Example:
cd src/sqitch
# Deploy all changes in upgrade.plan to the upgrade_debug database in the PostgreSQL 17 server.
sqitch deploy upgrade17
```

## Building

Building pgTAP_fixture constitutes combining all of the sql files used in *upgrade.plan* and *install.plan* into sql files that can be used in a PostgreSQL extension. All of the files in *install.plan* are combined into a single file *pgtap_fixture--x.x.x.sql*. Files between tagged versions in *upgrade.plan* are combined into files such as *pgtap_fixture--0.0.1--x.x.x.sql* and *pgtap_fixture--x.x.x--0.0.1*. If the last change in *upgrade.plan* is tagged, then "x.x.x" is replaced with the tag name.

Use [build/makefile](build/makefile) to build.
``` shell
cd build
make
```

Built files are saved to the [dist](dist) directory. A tar.gz archive is also created from the files in the dist directory and saved to the [zip](zip) directory. If the *dist* directory has old or extraneous files that aren't overwritten by make, then these will be included in the archive. Delete the *dist* directory before building to ensure that no such files are stored in the archive.

After building, you can install the extension in the PostgreSQL server.
``` shell
# Run an interactive bash shell in the PostgreSQL 17 server.
./db/container_utils.sh shell 17
# Navigate to the mounted directory that contains the built extension.
cd /pgtap_fixture/dist
# Install the extension in the server.
make install
```
Then in your database client, you can install the extension in the *deploy_debug* database, where you can debug it.
``` sql
create schema pgtap_fixture;
create extension pgtap_fixture schema pgtap_fixture;
```

## Releasing

Ensure that all tests pass for both *upgrade.plan* and *install.plan*.
``` shell
# Deploy all changes to the upgrade_debug and install_debug databases in the PostgreSQL 17 server.
sqitch -C test/sqitch deploy upgrade17
sqitch -C test/sqitch deploy install17
# Run all tests whose function names begin with "test_" in the upgrade_debug and install_debug databases in the PostgreSQL 17 server.
./test/run_tests.sh 17 upgrade_debug ^test_
./test/run_tests.sh 17 install_debug ^test_
```

Build the extension and ensure that its installer works.
``` shell
# Change to the build directory and make the makefile.
make -C build
# Run an interactive bash shell in the PostgreSQL 17 server.
./db/container_utils.sh shell 17
# Navigate to the mounted directory that contains the built extension.
cd /pgtap_fixture/dist
# Install the extension in the server.
make install
```

Use `sqitch tag` to tag the  version that is being released.
``` shell
# Change to the src/sqitch directory and tag last change in upgrade.plan with the version name 0.0.1.
sqitch -C src/sqitch tag --plan-file upgrade.plan 0.0.1
```

Never use `sqitch tag` in the tests' sqitch project or with *intall.plan* in the source's sqitch project. Only use it with *upgrade.plan* in the source's sqitch project.

Build the extension again. This time its version will reflect the new tag's name.
``` shell
# Delete the dist directory before building to ensure that no old or extraneous files are included in the archive.
rm -rf ./dist
# Change to the build directory and make the makefile.
make -C build
```

Tag the git repository with the version number.
``` shell
# Tag the repository.
git tag -a 0.0.1
# Push the tag to the remote.
git push origin 0.0.1
```

Upload the tar.gz file with the new version in the [zip](zip) directory to GitHub.

## Adding support for PostgreSQL versions

To add support for another PostgreSQL version, add a containerfile to [db/containers](db/containers) for that version. Ensure that *pgTAP* and *make* are installed in the container. Modify the functions in [db/container_utils.sh](db/container_utils.sh) to support using the the new containerfile, and ensure that its port does not conflict with the ports of other containers.

Add a plan for the new PostgreSQL version to [db/sqitch](db/sqitch). First copy and rename an existing plan and add a target to [db/sqitch/sqitch.conf](db/sqitch/sqitch.conf) for the new plan. If the copied plan doesn't work, then modify the new plan to make it compatible.

Modify [test/run_tests.sh](test/run_tests.sh) to support using the new PostgreSQL container.

Add targets to [test/sqitch/sqitch.conf](test/sqitch/sqitch.conf) and [src/sqitch/sqitch.conf](src/sqitch/sqitch.conf) to support deploying to the new PostgreSQL container.

Add a port for the new container to [.devcontainer/compose.yml](.devcontainer/compose.yml).

As more PostgreSQL versions are supported, it may become infeasible to expose a port on the host for every PostgreSQL version supported. It may be a good idea to expose a fixed number of ports on the host and develop a way to map which PostgreSQL containers are connected to them.