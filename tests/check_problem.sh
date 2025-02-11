#!bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <problem>"
    exit 1
fi

problem=$1

metadata=$(cat problems/$problem/meta.json)

function run_container () {
    image=$1
    cmd=$2
    docker run --rm --name test_runner $image bash -c "$cmd"
    if [ $? -ne 0 ]; then
        echo "failed to run container"
        exit 1
    fi
}

if [ -z "$metadata" ]; then
    echo "metadata not found"
    exit 1
fi

image=$(echo $metadata | jq -r .image)
docker pull $image
if [ $? -ne 0 ]; then
    echo "failed to pull image"
    exit 1
fi

answer=$(cat problems/$problem/answer)
if [ -z "$answer" ]; then
    echo "Answer code not found. Answer(or exec sample) code is required."
    exit 1
fi

tests=$(echo $metadata | jq -r .tests)
if [ "$tests" = "[]" ]; then
    echo "Tests not found so exec answer code only."
    exec_command="$answer"

    cmd=${command//[\[\]\",]/}
    cmd=${cmd/\{code\}/$exec_command}
    run_container $image "$cmd"
    exit 0
fi
command=$(echo $metadata | jq -r .exec_command)
if [ -z "$command" ]; then
    echo "tests exists but exec_command not found"
    exit 1
fi

answer_file=./problems/$problem/answer

echo "$tests" | jq -r '.[]' | while read -r test; do
    test_code=$(cat problems/$problem/tests/$test)
    exec_command="$answer"$'\n'"$test_code"

    cmd=${command//[\[\]\",]/}
    cmd=${cmd/\{code\}/$exec_command}
    run_container $image "$cmd"
done
