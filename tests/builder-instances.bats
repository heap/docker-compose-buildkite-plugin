#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"
load '../lib/shared'

# export DOCKER_STUB_DEBUG=/dev/tty

teardown() {
    if [[ -f "${BATS_MOCK_BINDIR}/docker" ]]; then
        unstub docker
    fi
}

@test "No Builder Instance Parameters" {

    stub docker \
        "buildx inspect : echo 'Name: test'" \
        "buildx inspect : echo 'Driver: driver'"

    run "$PWD"/hooks/pre-command

    assert_success
    assert_output "~~~ :docker: Using Default Builder 'test' with Driver 'driver'"
}

@test "Create Builder Instance with invalid Name" {
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_CREATE=true

    run "$PWD"/hooks/pre-command

    assert_failure
    assert_output "+++ 🚨 Builder Name cannot be empty when using 'create' or 'use' parameters"
}

@test "Use Builder Instance with invalid Name" {
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_USE=true

    run "$PWD"/hooks/pre-command

    assert_failure
    assert_output "+++ 🚨 Builder Name cannot be empty when using 'create' or 'use' parameters"
}

@test "Create Builder Instance with invalid Driver" {
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_CREATE=true
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_NAME=builder-name
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_DRIVER=""

    run "$PWD"/hooks/pre-command

    assert_failure
    assert_output --partial "+++ 🚨 Invalid driver: ''"
    assert_output --partial "Valid Drivers: docker-container, kubernetes, remote"
}

@test "Create Builder Instance with valid Driver" {
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_CREATE=true
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_NAME=builder-name
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_DRIVER=docker-container

    stub docker \
        "buildx inspect builder-name : exit 1" \
        "buildx create --name builder-name --driver docker-container --bootstrap : exit 0" \
        "buildx inspect : echo 'Name: test'" \
        "buildx inspect : echo 'Driver: driver'"

    run "$PWD"/hooks/pre-command

    assert_success
    assert_output \
        "~~~ :docker: Creating Builder Instance 'builder-name' with Driver 'docker-container'
~~~ :docker: Using Default Builder 'test' with Driver 'driver'"
}

@test "Create Builder Instance with valid Driver but already Exists" {
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_CREATE=true
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_NAME=builder-name
    export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILDER_DRIVER=docker-container

    stub docker \
        "buildx inspect builder-name : exit 0" \
        "buildx inspect : echo 'Name: test'" \
        "buildx inspect : echo 'Driver: driver'"

    run "$PWD"/hooks/pre-command

    assert_success
    assert_output \
        "~~~ :docker: Not Creating Builder Instance 'builder-name' as already exists
~~~ :docker: Using Default Builder 'test' with Driver 'driver'"
}
