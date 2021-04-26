#!/bin/bash

# run like this:
# cd path/to/project_root
# bash .scripts/macos.sh .

# CodeOcean Remote Client v0.7

#file_info format: <path/to/file/><file_name>=<id> (src/frog.java=34)
#file_path format: <path/to/file/><file_name>

GLOBIGNORE="*"

project_root="${1%/}"
declare -a file_array

function get_valid_file_path {
    file_path="$project_root/$1"
    if [ -e "$file_path" ]; then
        valid_file_path="$file_path"
    else
        file_name="${1##*/}"
        valid_file_path="$(find "$project_root" -name "$file_name" | head -1)"
        if ! [ "$valid_file_path" ]; then
            path_to_file="$(echo "$1" | pcregrep -o '^.+/')"
            echo "Error: $file_name is not in $project_root/$path_to_file and could not be found under $project_root."
            exit 1
        fi
    fi
    echo "$valid_file_path"
}

function get_escaped_file_content {
    file_path="$1"
    cat "$file_path" |
    perl -p -e 's@\\@\\\\@g' |
    perl -p -e 's@\r\n@\\n@g' |
    perl -p -e 's@\n@\\n@g' |
    perl -p -e 's@"@\\"@g'
}

function get_file_attributes {
    file_info="$1"
    file_path="$(get_valid_file_path "${file_info%=*}")"
    escaped_file_content="$(get_escaped_file_content "$file_path")"
    file_id="${file_info##*=}"
    echo "\"$2\": {\"file_id\": $file_id,\"content\": \"$escaped_file_content\"}"
}

function read_file_to_array {
    let i=0
    while IFS=$'\n' read -r line_data; do
        file_array[i]="${line_data}"
        ((++i))
    done < $1
}


co_file_path="$(get_valid_file_path '.co')"
read_file_to_array $co_file_path

validation_token="${file_array[0]}"

target_url="${file_array[1]}"

files_attributes="$(get_file_attributes "${file_array[2]}" 0)"

for ((i = 3; i < ${#file_array[@]}; i++)); do
    files_attributes+=", $(get_file_attributes "${file_array[i]}" $((i-2)))"
done

post_data="{\"remote_evaluation\": {\"validation_token\": \"$validation_token\",\"files_attributes\": {$files_attributes}}}"

curl -H 'Content-Type: application/json' --data "$(echo $post_data)" "$target_url"
echo
