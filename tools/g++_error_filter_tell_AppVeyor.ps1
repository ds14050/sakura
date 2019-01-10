Begin {
	filter   Strip-Escseq { $_ -creplace '\x1B\[[0-9;]*[a-zA-Z]', '' }
	filter   Quote-WQuote { $_ -creplace '"', '""' }
	function New-Context  { @{ File = ""; Function = ""; Line = $NULL; Column = $NULL; Category = ""; Messages = @() } }
	function Tell-Null     ($Context) {}
	function Tell-AppVeyor ($Context) {
		if (-not $Context.Category) {
			return
		}
		Add-AppveyorCompilationMessage`
			-FileName "$($Context.File)"`
			-Line $(+$Context.Line)`
			-Column $(+$Context.Column)`
			-Category "$(@{error="Error"; warning="Warning"; note="Information"}[$Context.Category])"`
			-Message "$($Context.Messages[0] |Quote-WQuote)"`
			-Details "$(@($Context.Function)+$Context.Messages[1..($Context.Messages.length-1)] -join "`n" |Quote-WQuote)"
	}
	$Tell = try {
		Get-Command -Name Add-AppveyorCompilationMessage -ErrorAction Stop
		Get-Command -Name Tell-AppVeyor
	} catch {
		Get-Command -Name Tell-Null
	}
	$Context = $NULL
}
Process {
	switch -regex -casesensitive ($_|Strip-Escseq) {
		# (example) dlg/CDlgOpenFile_CommonItemDialog.cpp: In member function 'virtual HRESULT CDlgOpenFile_CommonItemDialog::QueryInterface(const IID&, void**)':
		'^(..[^:]*): (In.+):$' {
			if ($Context) {
				&$Tell($Context)
			}
			$Context = New-Context
			$Context.File     = $Matches[1]
			$Context.Function = $Matches[2]
			$Matches[0]
			continue
		}
		# (example) dlg/CDlgOpenFile_CommonItemDialog.cpp:111:16: error: 'QITAB' does not name a type; did you mean 'CK_TAB'?
		'^(..[^:]*):(\d+):(\d+): (error|warning|note): (.*)$' {
			if ($Context) {
				&$Tell($Context)
				if (-not ($Context.File -ceq $Matches[1])) {
					$Context.Function = ""
				}
			} else {
				$Context = New-Context
			}
			$Context.File     =  $Matches[1]
			$Context.Line     = +$Matches[2]
			$Context.Column   = +$Matches[3]
			$Context.Category =  $Matches[4]
			$Context.Messages = ,$Matches[5]
			$Matches[0]
			continue
		}
		'^   (.+)$' {
			if ($Context) {
				$Context.Messages += $Matches[1]
			}
			$_
			continue
		}
		default {
			if ($Context) {
				&$Tell($Context)
				$Context = $NULL
			}
			$_
		}
	}
}
