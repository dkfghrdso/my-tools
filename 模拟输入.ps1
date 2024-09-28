Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 提示用户拖入文件
$txtFile = Read-Host "请将包含输入内容的txt文件拖入此窗口，然后按回车"

# 检查文件是否存在
if (-Not (Test-Path $txtFile)) {
    Write-Host "文件不存在，请确认文件路径正确。" -ForegroundColor Red
    exit
}

# 读取txt文件中的内容，指定UTF8编码以避免中文乱码
$content = Get-Content -Path $txtFile -Encoding UTF8

# 将多行合并为单行，以便按顺序输入
$content = $content -join "`n"

# 等待用户准备好焦点窗口
Write-Host "请在5秒内切换到目标窗口..."
Start-Sleep -Seconds 5

# 输入txt文件中的内容
[System.Windows.Forms.SendKeys]::SendWait($content)
