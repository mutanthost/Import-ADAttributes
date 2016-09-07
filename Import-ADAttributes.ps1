Function Import-ADAttributes([String]$DomainName,[String]$CSVFile,[String]$Logging="N")
    {
<#
.SYNOPSIS
   Update Active Directory User attributes in a bulk modus. Data is provide via a CSV - file with result output on screen or logging.
.DESCRIPTION
   The Import-ADAttributes will update Active Directory User attributes in a bulk modus. The data has been provide by a CSV file.
   The headers of the CSV file will be the AD User attributes. The import process will import the data depending on the headers in the file.
   So no pre - defined fields needed in the script, just put them in the header of the CSV - file.
   The result can been shown on your screen or can be stored in a logging file. 
.EXAMPLE
   Import-ADAttributes -domain example.net -CSVFile c:\import.csv -Logging N
   Import the CSV - file: c:\import.csv into the domain "example.net" with result output shown on the screen.
   The import data is depending of the header of the CSV - file.
.EXAMPLE
   Import-ADAttributes -domain example.net -CSVFile c:\import.csv -Logging Y
   Import the CSV - file: c:\import.csv into the domain "example.net" with result output written to a log file store in the same directory as the script under the folder \log\.
   The import data is depending of the header of the CSV - file.
.NOTES
    Author: Frederik Bisback
    Created on: 07/09/2016
    Version: 1.0.0
.LINK
   http://blog.pronict.net
#>
        ############
        # INCLUDES #
        ############
        import-module  activedirectory
        #End Includes

        #############
        # VARIABLES #
        #############
        #Define the location path of the script.
        $ScriptRoot = $PSScriptRoot#Split-Path $MyInvocation.MyCommand.Path
       
        #Define the name of the script.
        $LogNme = [io.path]::GetFileNameWithoutExtension(($MyInvocation.MyCommand).Name)

        #Create date variables
        $date_long = Get-Date
        $year = $date_long.Year
        $month = $date_long.Month.ToString("00")
        $day = $date_long.Day.ToString("00")
        $hour = $date_long.Hour.ToString("00")
        $min = $date_long.Minute.ToString("00")
        $logdate = "$year" + "$month" + "$day" + "$hour" + "$min"

        #Variables AD Attributes
        $AD_Attrib = @()
        $Header = @()
        $WorkDay_Import = @()

        #End Variables
        #################
        # START PROCESS #
        #################        

        Write-Host "Process will import the data into the domain" -ForegroundColor Yellow
        if($logging -eq "N")
            {
                $i = 0
                #NO LOGGING / NO REPORT
                Write-Host "The process will not be logged" -ForegroundColor Yellow

                #Getting headers of the CSV file
                Try
                    {
                        $AD_Attrib = Import-CSv $CSVFile -Verbose -ErrorAction Stop
                    }
                Catch
                    {
                        Write-Host "Import CSV file has not been detected. Please check location file or file may by missing." -ForegroundColor White -BackgroundColor Red
                        Break
                    }

                $AD_Attrib = $AD_Attrib[0] | gm -membertype noteproperty | select name
                $AD_Attrib_Cnt = $AD_Attrib.Count
                        
                While ($i -lt $AD_Attrib_Cnt)
                    {
                        $Header += $AD_Attrib.Name[$i]
                        $i++
                    }
                #End - Getting headers of the CSV file
                                
                        
                    Try
                    {
                        $WorkDay_Import = Import-Csv $CSVFile -Verbose -ErrorAction Stop
                    }
                Catch
                    {
                        Write-Host "Error has been detected during import of the CSV file." -ForegroundColor White -BackgroundColor Red
                        Break
                    }

                Write-Host "CSV file import has been completed. (Report: No / Logging: No)" -ForegroundColor White -BackgroundColor Green
                        
                #Create cononical domain name. This will always create a correct CN name of the entered domain name. (example 1: lit.lhoist.com >> DC=LIT,DC=LHOIST,DC=COM)
                $DNSplit = $DomainName.Split(".")
                $DNCnt = $DNSplit.Count
                $y=0
                $DNCN=""

                While ($y -lt $DNCnt)
                {
                    if($y -eq ($DNCnt-1) )
                        {
                            $DNCN += "DC="+$DNSplit[$y]
                        }
                    else
                        {
                            $DNCN += "DC="+$DNSplit[$y]+","
                        }
                    $y++
                }
                #End - Create cononical domain name.

                foreach ($Employee in $WorkDay_Import)
                    {
                        $mail = $Employee.mail
                        $ADUser = Get-ADUSer -SearchBase $DNCN -filter {mail -eq $mail} -Properties sAMAccountName

                                
                        if(!$ADUser)
                            {
                                Write-Host "Email address not found in AD ($mail)." -ForegroundColor Red
                                Write-Host "Attribution import for user $mail has been stopped" -ForegroundColor White -BackgroundColor DarkRed
                                        
                            }
                        else 
                            {
                                Write-Host "Email address found in AD ($mail)." -ForegroundColor Green
                                        
                                #Check attributes user
                                        
                                foreach ($AttrItem in $AD_Attrib)
                                    { 
                                        #write-host $AttrItem.name -ForegroundColor Blue -BackgroundColor White
                                        if($AttrItem.Name -eq "FirstName" -or $AttrItem.Name -eq "Mail" -or $AttrItem.Name -eq "LastName")
                                            {
                                                # DO NOTHING
                                                $attr = $AttrItem.Name
                                                Write-Host "$attr is excluded from the import." -ForegroundColor DarkYellow
                                            }
                                        else 
                                            {
                                                $attr = $AttrItem.Name  
                                                $EmplAttrValue = $Employee.$attr                                                                             
                                                $ADEmplAttrValues = Get-ADUser -filter {mail -like $mail} -Properties * | select -property $AttrItem.Name

                                                if($ADEmplAttrValues.$attr -contains $EmplAttrValue)
                                                    {
                                                        Write-Host $AttrItem.Name "has been filled in and/or not changed." -ForegroundColor Green
                                                    }
                                                else 
                                                    {
                                                        Write-Host $attr "is not filled in and/or value has been changed!" -ForegroundColor Red
                                                        $replaceValue = New-Object HashTable
                                                        $replaceValue.Add("$($attr)","$EmplAttrValue")

                                                        Try
                                                            {
                                                                Get-ADUser -Filter {mail -like $mail} | Set-ADUser -Replace $replaceValue
                                                            }
                                                        Catch
                                                            {
                                                                Write-Host "Adding/Updating of the AD user attribute has FAILED!" -ForegroundColor White -BackgroundColor Red
                                                                Break
                                                            }

                                                    }
                                                                 
                                        }                                          
                                                    
                                              
                                    }

                                #End Check attributes user
                            }
                    }
            }
        else
            {
                $i = 0
                #LOGGING YES
                Write-Host "The process will be logged" -ForegroundColor Green
                ############
                # INCLUDES #
                ############
                #Include created New Log File.
                . "$ScriptRoot\include\New-Log.ps1" 
                . "$ScriptRoot\include\Write-Log.ps1"
                . "$ScriptRoot\include\Invoke-LogRotation.ps1"
                #End Includes

                #Create new log File
                $LogNme = [io.path]::GetFileNameWithoutExtension(($MyInvocation.MyCommand).Name)
                $log = $ScriptRoot + "\log\" + $logNme + $logdate + ".log"
                New-Log $log -Header 'Import User AD attributes' -Append -Format 'PlainText'
                Write-Log "Import User AD attributes started ..." -LogType Information

                #Getting headers of the CSV file
                Try
                    {
                        $AD_Attrib = Import-CSv $CSVFile -Verbose -ErrorAction Stop
                    }
                Catch
                    {
                        Write-Host "Import CSV file has not been detected. Please check location file or file may by missing." -ForegroundColor White -BackgroundColor Red
                        Write-Log "Import CSV file has not been detected. Please check location file or file may by missing." -LogType Error
                        Break
                    }

                $AD_Attrib = $AD_Attrib[0] | gm -membertype noteproperty | select name
                $AD_Attrib_Cnt = $AD_Attrib.Count
                        
                While ($i -lt $AD_Attrib_Cnt)
                    {
                        $Header += $AD_Attrib.Name[$i]
                        $i++
                    }
                #End - Getting headers of the CSV file
                                
                    Try
                    {
                        $WorkDay_Import = Import-Csv $CSVFile -Verbose -ErrorAction Stop
                    }
                Catch
                    {
                        Write-Host "Error has been detected during import of the CSV file." -ForegroundColor White -BackgroundColor Red
                        Write-Log "Error has been detected during import of the CSV file." -LogType Error
                        Break
                    }

                Write-Host "CSV file import has been completed." -ForegroundColor White -BackgroundColor Green
                Write-Log "CSV file import has been completed. (Report: No / Logging: Yes)" -LogType SuccessAudit
    
                #Create cononical domain name. This will always create a correct CN name of the entered domain name. (example 1: lit.lhoist.com >> DC=LIT,DC=LHOIST,DC=COM)
                $DNSplit = $DomainName.Split(".")
                $DNCnt = $DNSplit.Count
                $y=0
                $DNCN=""

                While ($y -lt $DNCnt)
                {
                    if($y -eq ($DNCnt-1) )
                        {
                            $DNCN += "DC="+$DNSplit[$y]
                        }
                    else
                        {
                            $DNCN += "DC="+$DNSplit[$y]+","
                        }
                    $y++
                }
                #End - Create cononical domain name.

                    foreach ($Employee in $WorkDay_Import)
                    {
                        $mail = $Employee.mail
                        $ADUser = Get-ADUSer -SearchBase $DNCN -filter {mail -eq $mail} -Properties sAMAccountName

                                
                        if(!$ADUser)
                            {
                                Write-Host "Email address not found in AD ($mail)." -ForegroundColor Red
                                Write-log "Email address not found in AD ($mail)." -LogType Error
                                Write-Host "Attribution import for user $mail has been stopped" -ForegroundColor White -BackgroundColor DarkRed
                                        
                            }
                        else 
                            {
                                Write-Host "Email address found in AD ($mail)." -ForegroundColor Green
                                Write-log "Email address found in AD ($mail)." -LogType SuccessAudit
                                #Check attributes user
                                        
                                foreach ($AttrItem in $AD_Attrib)
                                    { 
                                        #write-host $AttrItem.name -ForegroundColor Blue -BackgroundColor White
                                        if($AttrItem.Name -eq "FirstName" -or $AttrItem.Name -eq "Mail" -or $AttrItem.Name -eq "LastName")
                                            {
                                                # DO NOTHING
                                                $attr = $AttrItem.Name
                                                Write-Host "$attr is excluded from the import." -ForegroundColor DarkYellow
                                                Write-log "$attr is excluded from the import." -LogType Information
                                            }
                                        else 
                                            {
                                                $attr = $AttrItem.Name  
                                                $EmplAttrValue = $Employee.$attr                                                                             
                                                $ADEmplAttrValues = Get-ADUser -filter {mail -like $mail} -Properties * | select -property $AttrItem.Name

                                                if($ADEmplAttrValues.$attr -contains $EmplAttrValue)
                                                    {
                                                        Write-Host $AttrItem.Name "has been filled in and/or not changed." -ForegroundColor Green
                                                        Write-Log "$attr has been filled in and/or not changed." -LogType SuccessAudit
                                                    }
                                                else 
                                                    {
                                                        Write-Host $attr "is not filled in and/or value has been changed!" -ForegroundColor Yellow
                                                        Write-Log "$attr is not filled in and/or value has been changed!" -LogType Information
                                                        $replaceValue = New-Object HashTable
                                                        $replaceValue.Add("$($attr)","$EmplAttrValue")

                                                        Try
                                                            {
                                                                Get-ADUser -Filter {mail -like $mail} | Set-ADUser -Replace $replaceValue
                                                            }
                                                        Catch
                                                            {
                                                                Write-Host "Adding/Updating of the AD user attribute has FAILED!" -ForegroundColor White -BackgroundColor Red
                                                                Write-Log "Adding/Updating of the AD user attribute has FAILED!" -LogType Error
                                                                Break
                                                            }

                                                        Write-Host "Adding/Updating of the AD user attribute has been completed!" -ForegroundColor White -BackgroundColor Green
                                                        Write-Log "Adding/Updating of the AD user attribute has been completed!" -LogType SuccessAudit

                                                    }
                                                                 
                                            }                                          
                                                   
                                              
                                    }

                                #End Check attributes user
                            }                
                    }
            }
    }
   
#End Process
