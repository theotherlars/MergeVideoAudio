Function Get-FileBrowser(){   
    param(
        [string]$initialDirectory,
        [ValidateSet("Video","Audio","Output")]$FileType
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    switch ($FileType) {
        "Video" {
            $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $FileDialog.Title = "Find Video File"
            $FileDialog.filter = "All files (*.*)| *.*"
        }
        "Audio" {
            $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $FileDialog.Title = "Find Audio File"
            $FileDialog.filter = "All files (*.*)| *.*"
        }
        "Output" {
            $FileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $FileDialog.Title = "Save File Location"
            $FileDialog.FileName = ".avi"
            $FileDialog.Filter = "AVI | *.avi"
        }
        Default {}
    }    
    $FileDialog.initialDirectory = $initialDirectory
    $FileDialog.ShowDialog() | Out-Null
    $FileDialog.filename
}

# Get script location
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript"){ 
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition 
}
else{ 
    $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}
# look for the ffmpeg.exe file
$pathFFMPEG = "$ScriptPath\ffmpeg.exe"
if(!(Test-Path -Path $pathFFMPEG)){
    return [System.Windows.Forms.MessageBox]::Show("Check ffmpeg.exe file path is $ScriptPath\ffmpeg.exe or download ffmpeg.exe at https://ffmpeg.org/ and place the ffmpeg.exe in the same folder as this script","Error: ffmpeg.exe not found",'OK','Error') | Out-Null    
}

# Fetch path to video file
$videoFile  = Get-FileBrowser -initialDirectory "c:\" -FileType Video
if($videoFile -ne [string]::Empty){
    
    # Fetch path to audio file
    $audioFile  = Get-FileBrowser -initialDirectory $videoFile -FileType Audio
    if($audioFile -ne [string]::Empty){
    
        # Fetch path to where the video file should be saved
        $outFile    = Get-FileBrowser -initialDirectory $videoFile -FileType Output
        $tempPath = $outFile.Remove($outFile.LastIndexOf("\"))
        if(($outFile -ne ".avi") -and ($outFile -ne [string]::Empty)){
    
            # format arguments and run the ffmpeg tool 
            $arguments = [string]::Format('-i "{0}" -i "{1}" -c copy -map 1:v:0 -map 0:a:0 -shortest "{2}"',$audioFile, $videoFile, $outfile)
            $p = Start-Process -FilePath $pathFFMPEG -ArgumentList $arguments -PassThru -Wait
            
            # Verify that the process when ok
            if($p.HasExited){
                if($p.ExitCode -eq 0){
                    explorer.exe $tempPath
                }
                else{
                    return [System.Windows.Forms.MessageBox]::Show("Script exited with error: $($p.ExitCode)","Error: $($p.ExitCode)",'OK','Error') | Out-Null
                }
            }           
        }
        else{
            return [System.Windows.Forms.MessageBox]::Show("Script exited.`nProvide a proper save path","Error: Invalid save path",'OK','Error') | Out-Null
        }        
    }
    else{
        return [System.Windows.Forms.MessageBox]::Show("Script exited.`nProvide a proper path to the audio file","Error: Invalid audio path",'OK','Error') | Out-Null
    }
}
else{
    return [System.Windows.Forms.MessageBox]::Show("Script exited.`nProvide a proper path to the video file","Error: Invalid video path",'OK','Error') | Out-Null
}