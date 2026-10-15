import os;
import json;
import shutil;
import xml.etree.ElementTree as ET;



LocalAppDataDirectory: str = (os.environ.get('LOCALAPPDATA') or '');
PluginsDirectory: str = os.path.join(LocalAppDataDirectory, 'Roblox', 'Plugins');
TargetRBXMXPath: str = os.path.join(PluginsDirectory, 'Silicon.rbxmx');
WorkspaceDirectory: str = os.path.dirname(os.path.abspath(__file__));
PluginSourceDirectory: str = os.path.join(WorkspaceDirectory, 'Plugin', 'Silicon');

ScriptMapping: dict[str, str] = {
	'Silicon':         os.path.join(PluginSourceDirectory, 'Source.server.luau'),
	'Create':          os.path.join(PluginSourceDirectory, 'Create', 'Source.shared.luau'),
	'GetDependencies': os.path.join(PluginSourceDirectory, 'Create', 'GetDependencies', 'Source.shared.luau'),
	'Services':        os.path.join(PluginSourceDirectory, 'Shared', 'Services', 'Source.shared.luau'),
	'Settings':        os.path.join(PluginSourceDirectory, 'Shared', 'Settings', 'Source.shared.luau'),
	'Types':           os.path.join(PluginSourceDirectory, 'Shared', 'Types', 'Source.shared.luau'),
	'Variables':       os.path.join(PluginSourceDirectory, 'Shared', 'Variables', 'Source.shared.luau'),
	'Synchronize':     os.path.join(PluginSourceDirectory, 'Synchronize', 'Source.shared.luau'),
	'Connect':         os.path.join(PluginSourceDirectory, 'Synchronize', 'Connect', 'Source.shared.luau'),
	'Export':          os.path.join(PluginSourceDirectory, 'Synchronize', 'Export', 'Source.shared.luau'),
	'APIService':      os.path.join(PluginSourceDirectory, 'Synchronize', 'Export', 'APIService', 'Source.shared.luau'),
	'API':             os.path.join(PluginSourceDirectory, 'Synchronize', 'Export', 'APIService', 'API', 'Source.shared.luau'),
	'References':      os.path.join(PluginSourceDirectory, 'Synchronize', 'Export', 'APIService', 'References', 'Source.shared.luau'),
	'Import':          os.path.join(PluginSourceDirectory, 'Synchronize', 'Import', 'Source.shared.luau'),
	'Pad':             os.path.join(PluginSourceDirectory, 'Synchronize', 'Pad', 'Source.shared.luau'),
	'Run':             os.path.join(PluginSourceDirectory, 'Synchronize', 'Run', 'Source.shared.luau'),
	'Table':           os.path.join(PluginSourceDirectory, 'Synchronize', 'Table', 'Source.shared.luau'),
	'Clone':           os.path.join(PluginSourceDirectory, 'Synchronize', 'Table', 'Clone', 'Source.shared.luau'),
	'Merge':           os.path.join(PluginSourceDirectory, 'Synchronize', 'Table', 'Merge', 'Source.shared.luau'),
	'UI':              os.path.join(PluginSourceDirectory, 'UI', 'Source.shared.luau'),
};



def SynchronizeRibbonConfiguration() -> (None):
	RobloxDirectory: str = os.path.join(LocalAppDataDirectory, 'Roblox');
	RibbonAssetsDirectory: str = os.path.join(WorkspaceDirectory, 'Assets', 'Ribbon');
	SettingsYAMLPath: str = os.path.join(WorkspaceDirectory, 'Settings.yaml');
	ShowRibbonTab: bool = True;

	if os.path.isfile(SettingsYAMLPath):
		try:
			with open(SettingsYAMLPath, 'r', encoding = 'utf-8') as SettingsReader:
				SettingsContent: str = SettingsReader.read();

			if ('ShowRibbonTab                 : false' in SettingsContent):
				ShowRibbonTab = False;

		except Exception:
			pass;

	if not os.path.exists(RobloxDirectory):
		return;

	for EntryName in os.listdir(RobloxDirectory):
		CandidatePath: str = os.path.join(RobloxDirectory, EntryName);

		if os.path.isdir(CandidatePath) and EntryName.isdigit() and (EntryName != '0'):
			CustomTabsDirectory: str = os.path.join(CandidatePath, 'CustomRibbonTabs');
			os.makedirs(CustomTabsDirectory, exist_ok = True);

			SourceTabPath: str = os.path.join(RibbonAssetsDirectory, 'SiliconTab.json');
			DestinationTabPath: str = os.path.join(CustomTabsDirectory, 'SiliconTab.json');
			SourceLayoutPath: str = os.path.join(RibbonAssetsDirectory, 'RibbonLayout.json');
			DestinationLayoutPath: str = os.path.join(CustomTabsDirectory, 'RibbonLayout.json');

			if ShowRibbonTab:
				if os.path.exists(SourceTabPath):
					shutil.copy2(SourceTabPath, DestinationTabPath);
					print(f'[Silicon Packager] Synchronized SiliconTab.json to {DestinationTabPath}');

				if os.path.exists(SourceLayoutPath):
					shutil.copy2(SourceLayoutPath, DestinationLayoutPath);
					print(f'[Silicon Packager] Synchronized RibbonLayout.json to {DestinationLayoutPath}');

			else:
				if os.path.exists(DestinationTabPath):
					os.remove(DestinationTabPath);
					print(f'[Silicon Packager] Removed hidden SiliconTab.json from {DestinationTabPath}');

				if os.path.exists(DestinationLayoutPath):
					try:
						with open(DestinationLayoutPath, 'r', encoding = 'utf-8') as LayoutReader:
							LayoutData: dict = json.load(LayoutReader) or { };

						TabLayoutList: list = LayoutData.get('TabLayout', [ ]);
						FilteredList: list = [
							Entry
							for Entry in TabLayoutList
							if ((Entry.get('Identifier', { }).get('Filename')) != 'SiliconTab')
						];
						LayoutData['TabLayout'] = FilteredList;

						with open(DestinationLayoutPath, 'w', encoding = 'utf-8') as LayoutWriter:
							json.dump(LayoutData, LayoutWriter, indent = 4);

						print(f'[Silicon Packager] Updated RibbonLayout.json (SiliconTab hidden) at {DestinationLayoutPath}');

					except Exception:
						pass;

	return;

def SynchronizePluginModel() -> (bool):
	if not os.path.exists(TargetRBXMXPath):
		print(f'[Silicon Packager] Target RBXMX file not found at: {TargetRBXMXPath}');

		return False;

	DocumentTree: ET.ElementTree = ET.parse(TargetRBXMXPath);
	DocumentRoot: ET.Element = DocumentTree.getroot();
	UpdatedCount: int = 0;

	for ItemElement in DocumentRoot.iter('Item'):
		PropertiesElement: ET.Element | None = ItemElement.find('Properties');

		if PropertiesElement is not None:
			NameElement: ET.Element | None = PropertiesElement.find("string[@name='Name']");
			SourceElement: ET.Element | None = PropertiesElement.find("ProtectedString[@name='Source']");

			if (NameElement is not None) and (SourceElement is not None) and (NameElement.text in ScriptMapping):
				ItemName: str = (NameElement.text or '');
				FilePath: str = ScriptMapping[ItemName];

				if os.path.exists(FilePath):
					with open(FilePath, 'r', encoding = 'utf-8') as FileReader:
						NewContent: str = FileReader.read();

					NormalizedCurrent: str = (SourceElement.text or '').replace('\r\n', '\n').strip();
					NormalizedNew: str = NewContent.replace('\r\n', '\n').strip();

					if NormalizedCurrent != NormalizedNew:
						SourceElement.text = NewContent;
						UpdatedCount += 1;

						print(f'[Silicon Packager] Updated script source: <{ItemName}>');

	if (UpdatedCount > 0):
		DocumentTree.write(TargetRBXMXPath, encoding = 'utf-8', xml_declaration = True);

		print(f'[Silicon Packager] Successfully saved {UpdatedCount} updated script(s) to {TargetRBXMXPath}');

	else:
		print('[Silicon Packager] All scripts are up to date in Silicon.rbxmx.');

	return True;

def Main() -> (None):
	print('====================================================');
	print('             Silicon Plugin Packager                ');
	print('====================================================');

	SynchronizeRibbonConfiguration();
	SynchronizePluginModel();

	print('[Silicon Packager] Done.');

	return;



if (__name__ == '__main__'):
	Main();
