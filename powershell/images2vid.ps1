# Define parameters for this script, requiring a folder path
param (
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

#add namespace for image processing
Add-Type -AssemblyName System.Drawing

$optimalWidth = 1 # to store max width

# Define ffmpeg arguments for video creation from images
# $ffmpegArgs = "-f", "image2", "-framerate", "2", "-i", "%05d.png", "-c:v", "libx264", "output.mkv"
$ffmpegArgs = "-f", "image2", "-framerate", "2", "-i", "%05d.png", "-vf", "scale=w=1280:h=-2", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "output.mp4"

# Function to check the folder for image files and set the appropriate input format for ffmpeg
function ImageCheck {
    # Get a list of .png and .jpg files in the folder
    $pngFiles = Get-ChildItem -Path $FolderPath -Filter *.png -Recurse -File
    $jpgFiles = Get-ChildItem -Path $FolderPath -Filter *.jpg -Recurse -File

    Write-Output "pngFiles: $($pngFiles.Count), jpgFiles: $($jpgFiles.Count)"

    # if there are less than 2 files, exit
    if ($pngFiles.Count -lt 2 -and $jpgFiles.Count -lt 2) {
        Write-Warning "The folder contains less than 2 .png or .jpg files. Exiting..."
        exit 1
    }

    # Check for both .png and .jpg files, output a warning and exit if found
    if ($pngFiles -and $jpgFiles) {
        Write-Warning "The folder contains both .png and .jpg files. Exiting..."
        exit 1
    } elseif ($pngFiles) {
        #Write-Output "The folder contains .png files only."
    } elseif ($jpgFiles) {
        #Write-Output "The folder contains .jpg files only."
        $ffmpegArgs[5] = "%05d.jpg"
    }
    else {
        Write-Output "The folder contains no .png or .jpg files."
    }
    
}

# calculates the optimal width for all image files
function GetOptimalImageSize {
    # Get all PNG / JPG files in the folder
    $imageFiles = Get-ChildItem -Path $FolderPath -Recurse -Include "*.png","*.jpg"

    $i = 0
    $totalFiles = $imageFiles.Count
    $progress = 0

    $maxWidth = 1
    $image = New-Object System.Drawing.Bitmap 1, 1 # Create a reusable image object
    foreach ($imageFile in $imageFiles) {
        try {
            # Load the image file into the reusable image object
            $image = [System.Drawing.Image]::FromFile($imageFile.FullName)
            $i++

            # Check if the image is loaded
            if ($image -eq $null) {
                Write-Error "Error: Failed to load image $($imageFile.FullName)"
                continue
            }

            # Get dimensions
            $width = $image.Width
            #$height = $image.Height

            #Write-Host "  $($imageFile.Name) @ $($width)x$($height)"

            # Update the optimal if the current is greater
            if ($width -gt $maxWidth) {
                $maxWidth = $width
            }

            # Dispose of the image to free memory
            $image.Dispose()

            # Update progress bar
            $progress = [math]::Round(($i / $totalFiles) * 100)
            Write-Progress -Activity "Reading Image Sizes" -Status "$progress% Complete" -PercentComplete $progress
        } catch {
            Write-Error "Error: Exception while processing $($imageFile.FullName) $($_.Exception.Message)"
        }
    }

    return $maxWidth
}

# Function to process images and create a video using ffmpeg
function ProcessImages {

    Write-Output "ProcessImages"

    # Get a sorted list of image files in the folder
    $fileList = Get-ChildItem -Path $FolderPath -Recurse -Include "*.png","*.jpg" | Sort-Object Name

    # Create a staging folder to store renamed image files
    $stagingFolderPath = Join-Path -Path $FolderPath -ChildPath "staging"
    if (Test-Path $stagingFolderPath) {
        Remove-Item -Path $stagingFolderPath -Recurse -Force
    }
    New-Item -Path $stagingFolderPath -ItemType Directory -Force

    $i = 0
    $totalFiles = $fileList.Count
    $progress = 0

    foreach ($file in $fileList) {
        $newName = ("{0:d5}" -f $i) + $file.Extension
        $destination = Join-Path -Path $stagingFolderPath -ChildPath $newName
        Copy-Item $file.FullName -Destination $destination
        $i++

        # Update progress bar
        $progress = [math]::Round(($i / $totalFiles) * 100)
        Write-Progress -Activity "Copying Images" -Status "$progress% Complete" -PercentComplete $progress
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

    # generate a new name for the output file based on the folder name
    $outputFileName = (Get-Item $FolderPath).Name + ".mp4"
    
    # rename and relocate the output file to the original folder
    $outputFilePath = Join-Path -Path $FolderPath -ChildPath $outputFileName

    # write message to console
    Write-Output "Moving output file to $outputFilePath"

    Move-Item -Path "$stagingFolderPath\output.mp4" -Destination $outputFilePath -Force

    # Remove the staging folder
    Remove-Item -Path $stagingFolderPath -Recurse -Force

}

# Verify the folder path exists before running the functions
if (Test-Path $FolderPath) {
    # Check if there are any image files in the folder
    $imageFiles = Get-ChildItem -Path $FolderPath -Recurse -Include "*.png","*.jpg"
    if ($imageFiles.Count -eq 0) {
        Write-Error "The folder contains no .png or .jpg files. Exiting..."
        exit 1
    }

    ImageCheck
    $optimalWidth = GetOptimalImageSize
    #ensure we have a width
    if ($optimalWidth -gt 0) {
        #update ffmpeg params optimal width
        $ffmpegArgs[7] = "scale=w=$($optimalWidth):h=-2"
        # Output the updated ffmpeg arguments
        Write-Output $ffmpegArgs
        ProcessImages
    }   
} else {
    Write-Error "The specified folder path does not exist."
}
