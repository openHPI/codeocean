# run like this:
# cd path\to\project_root
# powershell.exe -noprofile -executionpolicy bypass -file .scripts\windows.ps1 .

# CodeOcean Remote Client v0.6

#file_info format: <path/to/file/><file_name>=<id> (src/frog.java=34)
#file_path format: <path/to/file/><file_name>

param (
    [string]$project_root
)
if ( !($project_root | select-string -pattern '[/\\]$') ){
    $project_root += '/'
}


function post_web_request ($content_type, $data, $url){
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($data)
    [System.Net.HttpWebRequest] $web_request = [System.Net.WebRequest]::Create($url)
    $web_request.Method = 'POST'
    $web_request.ContentType = $content_type
    $web_request.ContentLength = $buffer.Length;

    $request_stream = $web_request.GetRequestStream()
    $request_stream.Write($buffer, 0, $buffer.Length)
    $request_stream.Flush()
    $request_stream.Close()

    [System.Net.HttpWebResponse] $web_response = $web_request.GetResponse()
    $stream_reader = new-object System.IO.StreamReader($web_response.GetResponseStream())
    $result = $stream_reader.ReadToEnd()
    return $result
}

function find_file ($file_name){
    $search_result = get-childitem -recurse -path $project_root -filter $file_name
    if( !$search_result.exists ){
        write-host "Error: $file_name could not be found under $project_root."
        exit 1
    }elseif( $search_result.gettype().name -eq 'Object[]' ){
        $search_result = $search_result[0]
    }
    return $search_result
}

function get_file ($file_path){
    $path_to_file = $project_root
    $path_to_file += ($file_path | select-string -pattern '^.+/').matches.value
    $file_name = ($file_path | select-string -pattern '[^/]+$').matches.value
    $file = get-childitem -path $path_to_file -filter $file_name
    if( !$file.exists ){
        write-host "Warning: $file_name should be in $path_to_file, but it is not. Searching whole project..."
        $file = find_file $file_name
        write-host 'Using '$file.fullname'.'
    }
    return $file
}

function get_escaped_file_content ($file){
    $content = [IO.File]::ReadAllText($file.fullname)
    $content = $content.replace('\', '\\')
    $content = $content -replace "`r`n", '\n'
    $content = $content -replace "`n", '\n'
    $content = $content -replace "`t", '\t'
    $content = $content.replace('"', '\"')
    return $content
}

function get_file_attributes ($file_info, $index){
    $file = get_file ($file_info | select-string -pattern '^.*(?==)').matches.value
    $escaped_file_content = get_escaped_file_content $file
    $file_id = ($file_info | select-string -pattern '[^=]+$').matches.value
    return "`"$index`": {`"file_id`": $file_id,`"content`": `"$escaped_file_content`"}"
}

$co_file = get_file '.co'

$file_array = get-content $co_file.fullname

$validation_token = $file_array[0]

$target_url = $file_array[1]

$files_attributes = get_file_attributes $file_array[2] 0

for ($i = 3; $i -lt $file_array.length; $i++){
    $files_attributes += ', '
    $files_attributes += get_file_attributes $file_array[$i] ($i-2)
}

$post_data = "{`"remote_evaluation`": {`"validation_token`": `"$validation_token`",`"files_attributes`": {$files_attributes}}}"

post_web_request 'application/json' $post_data $target_url
