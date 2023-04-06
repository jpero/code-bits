# Define parameters for this script, requiring a folder path
param (
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

# Define ffmpeg arguments for video creation from images
# $ffmpegArgs = "-f", "image2", "-framerate", "2", "-i", "%05d.png", "-c:v", "libx264", "output.mkv"
$ffmpegArgs = "-f", "image2", "-framerate", "2", "-i", "%05d.png", "-vf", "scale=w=1280:h=720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "output.mp4"

# Function to check the folder for image files and set the appropriate input format for ffmpeg
function ImageCheck {
    param (
        [string]$Path
    )

    # Get a list of .png and .jpg files in the folder
    $pngFiles = Get-ChildItem -Path $Path -Filter *.png -Recurse -File
    $jpgFiles = Get-ChildItem -Path $Path -Filter *.jpg -Recurse -File

    # Check for both .png and .jpg files, output a warning and exit if found
    if ($pngFiles -and $jpgFiles) {
        Write-Warning "The folder contains both .png and .jpg files. Exiting..."
        exit 1
    } elseif ($pngFiles) {
        Write-Output "The folder contains .png files only."
    } elseif ($jpgFiles) {
        Write-Output "The folder contains .jpg files only."
        $ffmpegArgs[5] = "%05d.jpg"
    } else {
        Write-Output "The folder contains no .png or .jpg files."
    }

    # Output the updated ffmpeg arguments
    Write-Output $ffmpegArgs
}

# Function to process images and create a video using ffmpeg
function ProcessImages {

    # Get a sorted list of image files in the folder
    $fileList = Get-ChildItem -Path $FolderPath -Recurse -Include "*.png","*.jpg" | Sort-Object Name

    # Create a staging folder to store renamed image files
    $stagingFolderPath = Join-Path -Path $FolderPath -ChildPath "staging"
    New-Item -Path $stagingFolderPath -ItemType Directory -Force

    # Rename and copy image files to the staging folder
    $i = 1
    foreach ($file in $fileList) {
        $newName = ("{0:d5}" -f $i) + $file.Extension
        $destination = Join-Path -Path $stagingFolderPath -ChildPath $newName
        Copy-Item $file.FullName -Destination $destination
        $i++
    }

    # Run ffmpeg to create the video in the staging folder
    $process = Start-Process -FilePath "ffmpeg.exe" -ArgumentList $ffmpegArgs -WorkingDirectory $stagingFolderPath -NoNewWindow -Wait -PassThru

    # Check if ffmpeg encountered any errors
    if ($process.ExitCode -ne 0) {
        Write-Error "ffmpeg.exe encountered an error. Exit code: $($process.ExitCode)"
        exit 1
    } else {
        Write-Output "ffmpeg.exe completed successfully."
    }

}

# Verify the folder path exists before running the functions
if (Test-Path $FolderPath) {
    ImageCheck -Path $FolderPath
    ProcessImages
} else {
    Write-Error "The specified folder path does not exist."
}
