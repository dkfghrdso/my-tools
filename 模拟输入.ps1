Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ��ʾ�û������ļ�
$txtFile = Read-Host "�뽫�����������ݵ�txt�ļ�����˴��ڣ�Ȼ�󰴻س�"

# ����ļ��Ƿ����
if (-Not (Test-Path $txtFile)) {
    Write-Host "�ļ������ڣ���ȷ���ļ�·����ȷ��" -ForegroundColor Red
    exit
}

# ��ȡtxt�ļ��е����ݣ�ָ��UTF8�����Ա�����������
$content = Get-Content -Path $txtFile -Encoding UTF8

# �����кϲ�Ϊ���У��Ա㰴˳������
$content = $content -join "`n"

# �ȴ��û�׼���ý��㴰��
Write-Host "����5�����л���Ŀ�괰��..."
Start-Sleep -Seconds 5

# ����txt�ļ��е�����
[System.Windows.Forms.SendKeys]::SendWait($content)
