# Import-ADAttributes
Update Active Directory User attributes in a bulk modus. Data is provide via a CSV - file with result output on screen or logging.

The Import-ADAttributes will update Active Directory User attributes in a bulk modus. The data has been provide by a CSV file.
The headers of the CSV file will be the AD User attributes. The import process will import the data depending on the headers in the file.
So no pre - defined fields needed in the script, just put them in the header of the CSV - file.
The result can been shown on your screen or can be stored in a logging file. 

EXAMPLES

Import-ADAttributes -domain example.net -CSVFile c:\import.csv -Logging N

Import the CSV - file: c:\import.csv into the domain "example.net" with result output shown on the screen.
The import data is depending of the header of the CSV - file.

Import-ADAttributes -domain example.net -CSVFile c:\import.csv -Logging Y

Import the CSV - file: c:\import.csv into the domain "example.net" with result output written to a log file store in the same directory as the script under the folder \log\.
The import data is depending of the header of the CSV - file.

NOTES

Author: Frederik Bisback

Created on: 07/09/2016

Version: 1.0.0
