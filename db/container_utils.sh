#!/bin/bash

# Create a postgres container with the given version. It will be populated with databases for debugging
# as defined in the plan file in the db/sqitch directory for the given version. The container will have
# the directory /pgtap_fixture which corresponds with this project's directory and can be used for
# debugging the installer for the pgtap_fixture extension.
create () {
    if [ $(podman container ls --filter name=^$container_name$ | wc --lines) -gt 1 ]
    then
        printf "Postgres $postgres_version container has already been created!\n" >&2
        exit 1
    fi

    # The format must be "docker" for a containerfile that has a HEALTHCHECK statement.
    podman build \
        --format docker \
        --file postgres$postgres_version.containerfile \
        --tag $image_name \
        $script_dir/containers
    # Interprocess Communication (--ipc) is set to private, so that the shared memory size (--shm-size)
    # can be set for each container.
    # TODO: Make the shm-size configurable.
    # TODO: Make the host port configurable.
    podman container create \
        --name $container_name \
        --restart always \
        --ipc private --shm-size 128mb  \
        --env POSTGRES_PASSWORD=password --env PGDATA=/var/lib/postgresql/data/pgdata \
        --volume $data_volume_name:/var/lib/postgresql/data:Z \
        --volume $script_dir/..:/pgtap_fixture:ro \
        --publish 5432:5432 \
        localhost/$image_name
    podman container start $container_name
    
    # Because the podman container is being run inside another podman container, any healthcheck attempts
    # defined inside the containerfile will not run. This is because the container does not have the systemd
    # service. Instead, this loop performs the healthcheck attempts.
    wait_counter=0
    wait_interval_seconds=3
    wait_retries=10
    while [ "$(podman healthcheck run $container_name)" != "" ]
    do
        if [ $wait_counter = $wait_retries ]
        then
            printf "Waited %s seconds for container $container_name to be healthy. Giving up.\n" \
                $(($wait_counter * $wait_interval_seconds)) \
                >&2
            exit 1
        fi
        sleep $wait_interval_seconds
        wait_counter=$wait_counter+1
    done

    # Deploy the databases and roles for this postgres version to the container.
    sqitch -C $script_dir/sqitch deploy $postgres_version
}

# Remove the container and its data.
destroy () {
    podman container rm -f $container_name
    podman volume rm $data_volume_name
}

# Start the container.
start () {
    podman container start $container_name
}

# Stop the container.
stop () {
    podman container stop $container_name
}

# Get an interactive shell in the container.
shell () {
    podman exec -it $container_name /bin/bash
}

postgres_version=$2

# Get the directory where this script is located
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Check if the given version is supported.
case $postgres_version in
    17) ;;
    *)
        printf "Postgres version '%s' not recognized.\n" "$postgres_version" >&2
        exit 1
        ;;
esac

image_name=pgtap_fixture_postgres$postgres_version
container_name=pgtap_fixture_postgres$postgres_version
data_volume_name=pgtap_fixture_postgres${postgres_version}_data

# The first parameter to this script is the name of one of the above defined functions which should be
# run. The second parameter is the postgres version number. If the given function also takes more
# parameters, then any remaining parameters will be passed to the function.
func_name="$1"
shift 2
"$func_name" "$@"