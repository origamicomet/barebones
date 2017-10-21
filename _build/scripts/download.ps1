# Downloads a file.

trap {
  # Force errors to bubble correctly.
  exit 1
}

# Using WebClient to support Windows 7.
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile($args[0], $args[1])
