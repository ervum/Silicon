--!strict

return {
	CHS  = game:GetService('ChangeHistoryService'),
	SES  = game:GetService('ScriptEditorService'),
	HTTP = game:GetService('HttpService'),
	RS   = game:GetService('RunService'),
	D    = game:GetService('Debris')
} :: { [string]: ServiceProvider };