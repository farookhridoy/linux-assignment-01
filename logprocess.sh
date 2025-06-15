#!/bin/bash

KEYWORD_INFO="INFO:"
KEYWORD_WARNING="WARNING:"
KEYWORD_HTTP="HTTP:"

count_info=0
count_warning=0
count_http_2xx=0
count_http_4xx=0
total_lines_processed=0

process_line() {
    local log_line="$1"
    ((total_lines_processed++))

    if echo "$log_line" | grep -q "$KEYWORD_INFO"; then
        ((count_info++))
    fi

    if echo "$log_line" | grep -q "$KEYWORD_WARNING"; then
        ((count_warning++))
    fi

    if echo "$log_line" | grep -q "$KEYWORD_HTTP"; then
        local status_code
        status_code=$(echo "$log_line" | grep -oE 'status [0-9]{3}' | cut -d " " -f2)

        if [[ -n $status_code ]]; then
            case $status_code in
                2[0-9][0-9])
                    ((count_http_2xx++))
                    ;;
                4[0-9][0-9])
                    ((count_http_4xx++))
                    ;;
                5[0-9][0-9])
                    echo "HTTP 5xx error found"
                    ;;
                *)
                    echo "status code $status_code"
                    ;;
            esac
        fi
    fi
}

parse_log_file() {
    local file_name="$1"

    if [[ ! -f $file_name ]]; then
        echo "This is not a file."
        exit 2
    fi

    if [[ ! -r $file_name ]]; then
        echo "The log file ${file_name} is not readable"
        exit 3
    fi

    while IFS="" read -r line; do
        process_line "$line"
    done < "$file_name"

    echo "Total info count found: ${count_info}"
    echo "Total warning count found: ${count_warning}"
    echo "Total 2xx count found: ${count_http_2xx}"
    echo "Total 4xx count found: ${count_http_4xx}"
    echo "Total lines processed: ${total_lines_processed}"
}

# Call the function with provided file name
parse_log_file "$1"
