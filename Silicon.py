import urllib.parse;
import traceback;
import threading;
import argparse;
import requests;
import hashlib;
import shutil;
import ctypes;
import gzip;
import json;
import yaml;
import time;
import sys;
import io;
import os;

from ctypes      import wintypes;
from typing      import Any, Optional, Union, Tuple, Dict, List, Type, Set;
from argparse    import ArgumentParser, Namespace;
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer;
from threading   import Thread, Lock, Condition;



if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(line_buffering = True);

if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(line_buffering = True);



SiliconScriptDir: str = os.path.dirname(os.path.abspath(__file__));

def ResolveGameBasePath(ExplicitTarget: Optional[str] = None) -> (str):
    Target: Optional[str] = ExplicitTarget;

    if not Target and ('Settings' in globals()) and isinstance(Settings, dict):
        Target = Settings.get('TargetDirectory') or Settings.get('Target');

    if Target:
        AbsExplicit: str = os.path.abspath(Target);
        os.makedirs(AbsExplicit, exist_ok = True);

        return AbsExplicit;

    CurrentDir: str = os.getcwd();
    ScriptDir: str = SiliconScriptDir;

    if (os.path.basename(CurrentDir).lower() == 'game') or os.path.isdir(os.path.join(CurrentDir, 'Workspace')):
        return CurrentDir;

    if (os.path.basename(ScriptDir).lower() == 'silicon'):
        SiliconGameDir: str = os.path.join(ScriptDir, 'Game');
        os.makedirs(SiliconGameDir, exist_ok = True);

        return os.path.abspath(SiliconGameDir);

    LocalGameDir: str = os.path.join(CurrentDir, 'Game');

    if os.path.isdir(LocalGameDir):
        return os.path.abspath(LocalGameDir);

    LocalLowerGameDir: str = os.path.join(CurrentDir, 'game');

    if os.path.isdir(LocalLowerGameDir):
        return os.path.abspath(LocalLowerGameDir);

    FallbackPath: str = os.path.abspath(LocalGameDir);
    os.makedirs(FallbackPath, exist_ok = True);

    return FallbackPath;



ScriptPath: str = os.getcwd();
BasePath: str = ResolveGameBasePath();

DaemonArguments: List[Tuple[str, str, Type, str]] = [
    ('--Script',   '-S', str, 'Path to a certain script to be processed along with all its ancestry'),
    ('--Target',   '-p', str, 'Target directory where Game files are stored and synchronized'),
    ('--Settings', '-s', str, 'Path to Settings.yaml configuration file'),

    ('--Host',     '-H', str, 'Web host address of the local server to send data to'),
    ('--Port',     '-P', int, 'Port number of the local server to send data to'),

    ('--Requests', '-r', str, 'HTTPRequest types for the handler to enable'),
];

def SetSiliconRibbonTabVisible(IsVisible: bool, Silent: bool = False) -> (bool):
    ScriptDir: str = SiliconScriptDir;
    LocalLayoutPath: str = os.path.join(ScriptDir, 'Assets', 'Ribbon', 'RibbonLayout.json');
    LocalTabPath: str = os.path.join(ScriptDir, 'Assets', 'Ribbon', 'SiliconTab.json');
    SettingsYAMLPath: str = os.path.join(ScriptDir, 'Settings.yaml');
    TargetBool: bool = bool(IsVisible);
    UpdatedAny: bool = False;

    if os.path.isfile(SettingsYAMLPath):
        try:
            with open(SettingsYAMLPath, 'r', encoding = 'utf-8') as SettingsReader:
                YAMLText: str = SettingsReader.read();

            OldToken: str = 'ShowRibbonTab                 : true' if (not TargetBool) else 'ShowRibbonTab                 : false';
            NewToken: str = 'ShowRibbonTab                 : true' if TargetBool else 'ShowRibbonTab                 : false';

            if (OldToken in YAMLText):
                UpdatedYAMLText: str = YAMLText.replace(OldToken, NewToken, 1);

                with open(SettingsYAMLPath, 'w', encoding = 'utf-8') as SettingsWriter:
                    SettingsWriter.write(UpdatedYAMLText);

                UpdatedAny = True;

        except Exception as YAMLError:
            if not Silent:
                LogException(YAMLError, f'update ShowRibbonTab in {SettingsYAMLPath}!');

    if os.path.isfile(LocalLayoutPath):
        try:
            with open(LocalLayoutPath, 'r', encoding = 'utf-8') as LocalReader:
                LocalLayoutData: Dict[str, Any] = json.load(LocalReader) or { };

            LocalTabList: List[Dict[str, Any]] = LocalLayoutData.get('TabLayout', [ ]);
            LocalChanged: bool = False;
            FoundLocalSilicon: bool = False;

            for LocalTabEntry in LocalTabList:
                LocalIdentifier: Dict[str, Any] = LocalTabEntry.get('Identifier', { });

                if (LocalIdentifier.get('Filename') == 'SiliconTab'):
                    FoundLocalSilicon = True;

                    if (LocalTabEntry.get('Visible') != TargetBool):
                        LocalTabEntry['Visible'] = TargetBool;
                        LocalChanged = True;

            if not FoundLocalSilicon:
                LocalTabList.append({
                    'Identifier': {
                        'Type'    : 'Custom',
                        'Filename': 'SiliconTab',
                    },
                    'Visible'   : TargetBool,
                });
                LocalLayoutData['TabLayout'] = LocalTabList;
                LocalChanged = True;

            if LocalChanged:
                with open(LocalLayoutPath, 'w', encoding = 'utf-8') as LocalWriter:
                    json.dump(LocalLayoutData, LocalWriter, indent = 4);

                UpdatedAny = True;

        except Exception as LocalLayoutError:
            if not Silent:
                LogException(LocalLayoutError, f'update RibbonLayout.json at {LocalLayoutPath}!');

    LocalAppDataDir: str = (os.environ.get('LOCALAPPDATA') or '');
    RobloxDir: str = os.path.join(LocalAppDataDir, 'Roblox');

    if LocalAppDataDir and os.path.isdir(RobloxDir):
        for EntryName in os.listdir(RobloxDir):
            CandidateDir: str = os.path.join(RobloxDir, EntryName);

            if os.path.isdir(CandidateDir) and EntryName.isdigit() and (EntryName != '0'):
                CustomTabsDir: str = os.path.join(CandidateDir, 'CustomRibbonTabs');
                UserLayoutPath: str = os.path.join(CustomTabsDir, 'RibbonLayout.json');
                UserTabPath: str = os.path.join(CustomTabsDir, 'SiliconTab.json');

                try:
                    os.makedirs(CustomTabsDir, exist_ok = True);

                    if TargetBool:
                        if os.path.isfile(LocalTabPath) and (not os.path.isfile(UserTabPath)):
                            shutil.copy2(LocalTabPath, UserTabPath);
                            UpdatedAny = True;

                    else:
                        if os.path.isfile(UserTabPath):
                            os.remove(UserTabPath);
                            UpdatedAny = True;

                    if (not os.path.isfile(UserLayoutPath)) and os.path.isfile(LocalLayoutPath):
                        shutil.copy2(LocalLayoutPath, UserLayoutPath);
                        UpdatedAny = True;

                    if os.path.isfile(UserLayoutPath):
                        with open(UserLayoutPath, 'r', encoding = 'utf-8') as Reader:
                            LayoutData: Dict[str, Any] = json.load(Reader) or { };

                        TabLayoutList: List[Dict[str, Any]] = LayoutData.get('TabLayout', [ ]);
                        LayoutChanged: bool = False;

                        if TargetBool:
                            FoundSiliconTab: bool = False;

                            for TabEntry in TabLayoutList:
                                Identifier: Dict[str, Any] = TabEntry.get('Identifier', { });

                                if (Identifier.get('Filename') == 'SiliconTab'):
                                    FoundSiliconTab = True;

                                    if (TabEntry.get('Visible') is not True):
                                        TabEntry['Visible'] = True;
                                        LayoutChanged = True;

                            if not FoundSiliconTab:
                                TabLayoutList.append({
                                    'Identifier': {
                                        'Type'    : 'Custom',
                                        'Filename': 'SiliconTab',
                                    },
                                    'Visible'   : True,
                                });
                                LayoutData['TabLayout'] = TabLayoutList;
                                LayoutChanged = True;

                        else:
                            FilteredTabs: List[Dict[str, Any]] = [
                                TabEntry
                                for TabEntry in TabLayoutList
                                if ((TabEntry.get('Identifier', { }).get('Filename')) != 'SiliconTab')
                            ];

                            if (len(FilteredTabs) != len(TabLayoutList)):
                                LayoutData['TabLayout'] = FilteredTabs;
                                LayoutChanged = True;

                        if LayoutChanged:
                            with open(UserLayoutPath, 'w', encoding = 'utf-8') as Writer:
                                json.dump(LayoutData, Writer, indent = 4);

                            UpdatedAny = True;

                except Exception as LayoutError:
                    if not Silent:
                        LogException(LayoutError, f'update CustomRibbonTabs in {CustomTabsDir}!');

    if (not Silent) or UpdatedAny:
        print(f'[Silicon Server] Custom Silicon Ribbon Tab visibility set to: {TargetBool}');

    return UpdatedAny;

NoDataAvailableResponse: Dict[str, str] = { 'Status': 'No data available' };
AliveResponse: Dict[str, str] = { 'Status': 'Alive', 'Server': 'Silicon', 'Version': '0.0.0' };

Server: Optional[ThreadingHTTPServer] = None;
ServerThread: Optional[Thread] = None;

Chunks: Dict[int, str] = { };
ChunkBuffers: Dict[str, Dict[int, str]] = { };

SuppressedHashes: Set[str] = set();
SuppressionLock: Lock = Lock();

RSConnected: bool = False;
LastRSContactTime: float = 0.0;
PendingRSClear: bool = False;

FileHashes: Dict[str, str] = { };
FileMTimes: Dict[str, float] = { };
KnownDirectories: Set[str] = set();
WatcherRunning: bool = True;

IgnoredDirectories: Set[str] = {
    '.git',
    '.vscode',
    '.idea',
    '__pycache__',
    '.venv',
    'node_modules',
    'scratch',
    '.trash',
};

def IsPathIgnored(RelativePath: str) -> (bool):
    NormalizedPath: str = RelativePath.replace('\\', '/').strip('/');

    if not NormalizedPath or (NormalizedPath == '.'):
        return False;

    Segments: List[str] = NormalizedPath.split('/');

    for IgnoredDir in IgnoredDirectories:
        if (IgnoredDir in Segments):
            return True;

    RootFolderName: str = Settings.get('RootFolderName', Settings.get('RecycleBinParent', 'Silicon'));
    PluginFolderName: str = Settings.get('PluginFolderName', 'Plugin');
    PluginFolderRelativePath: str = f'ReplicatedStorage/{RootFolderName}/{PluginFolderName}';

    if (NormalizedPath == PluginFolderRelativePath) or NormalizedPath.startswith(f'{PluginFolderRelativePath}/'):
        return True;

    if (NormalizedPath == 'ReplicatedStorage/Silicon/Plugin') or NormalizedPath.startswith('ReplicatedStorage/Silicon/Plugin/'):
        return True;

    return False;



class SHFILEOPSTRUCTW(ctypes.Structure):
    _fields_ = [
        ('hwnd',                  wintypes.HWND),
        ('wFunc',                 wintypes.UINT),
        ('pFrom',                 wintypes.LPCWSTR),
        ('pTo',                   wintypes.LPCWSTR),
        ('fFlags',                wintypes.WORD),
        ('fAnyOperationsAborted', wintypes.BOOL),
        ('hNameMappings',         wintypes.LPVOID),
        ('lpszProgressTitle',     wintypes.LPCWSTR),
    ];


FO_DELETE: int = 0x0003;
FOF_ALLOWUNDO: int = 0x0040;
FOF_NOCONFIRMATION: int = 0x0010;
FOF_SILENT: int = 0x0004;



class ChangeQueue:
    def __init__(self) -> (None):
        self.Lock: Lock = Lock();
        self.Condition: Condition = Condition(self.Lock);
        self.Events: List[Dict[str, Any]] = [ ];
        self.CurrentID: int = 0;

    def AddEvent(self, Action: str, Path: str, Source: Optional[str] = None, ClassName: Optional[str] = None, OriginalName: Optional[str] = None, FileHash: Optional[str] = None, Properties: Optional[Dict[str, Any]] = None, Attributes: Optional[Dict[str, Any]] = None, Tags: Optional[List[str]] = None, ScriptType: Optional[str] = None) -> (int):
        with self.Condition:
            self.CurrentID += 1;
            NewEvent: Dict[str, Any] = {
                'id'          : self.CurrentID,
                'action'      : Action,
                'path'        : Path.replace('\\', '/'),
                'source'      : Source,
                'className'   : ClassName,
                'originalName': OriginalName,
                'hash'        : FileHash or (ComputeSHA256(Source) if Source else ''),
                'properties'  : Properties,
                'attributes'  : Attributes,
                'tags'        : Tags,
                'scriptType'  : ScriptType,
                'timestamp'   : time.time(),
            };
            self.Events.append(NewEvent);

            if (len(self.Events) > 1000):
                self.Events = self.Events[-1000:];

            self.Condition.notify_all();

            return self.CurrentID;

    def GetEventsSince(self, SinceID: int, Timeout: float = 0.0) -> (Tuple[List[Dict[str, Any]], int]):
        with self.Condition:
            NewEvents: List[Dict[str, Any]] = [Event for Event in self.Events if (Event['id'] > SinceID)];

            if NewEvents or (Timeout <= 0.0):
                return NewEvents, self.CurrentID;

            self.Condition.wait(timeout = Timeout);
            NewEvents = [Event for Event in self.Events if (Event['id'] > SinceID)];

            return NewEvents, self.CurrentID;


ChangeEventsQueue: ChangeQueue = ChangeQueue();



def ComputeSHA256(Content: str) -> (str):
    return hashlib.sha256(Content.encode('utf-8')).hexdigest();

def ComputeFileSHA256(FilePath: str) -> (str):
    try:
        with open(FilePath, 'r', encoding = 'utf-8', errors = 'replace') as FileHandle:
            return ComputeSHA256(FileHandle.read());

    except Exception:
        return '';

def SendToRecycleBin(TargetDirectoryOrFilePath: str) -> (bool):
    if not os.path.exists(TargetDirectoryOrFilePath):
        return True;

    if (sys.platform == 'win32'):
        try:
            AbsPath: str = os.path.abspath(TargetDirectoryOrFilePath) + '\0\0';
            FileOp: SHFILEOPSTRUCTW = SHFILEOPSTRUCTW();
            FileOp.wFunc = FO_DELETE;
            FileOp.pFrom = AbsPath;
            FileOp.fFlags = (FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT);
            Result: int = ctypes.windll.shell32.SHFileOperationW(ctypes.byref(FileOp));

            return ((Result) == 0);

        except Exception as Error:
            LogException(Error, f'move {TargetDirectoryOrFilePath} to Windows Recycle Bin!');

    try:
        TrashDir: str = os.path.abspath('.trash');
        os.makedirs(TrashDir, exist_ok = True);
        DestPath: str = os.path.join(TrashDir, f'{(int(time.time()))}_{os.path.basename(TargetDirectoryOrFilePath)}');
        os.replace(TargetDirectoryOrFilePath, DestPath);

        return True;

    except Exception as Error:
        LogException(Error, f'move {TargetDirectoryOrFilePath} to fallback trash!');

        return False;

def MarkRSWrite(FilePath: str, ContentHash: str) -> (None):
    NormalizedPath: str = os.path.relpath(FilePath, BasePath).replace('\\', '/');

    with SuppressionLock:
        SuppressedHashes.add(ContentHash);
        FileHashes[NormalizedPath] = ContentHash;

        if os.path.exists(FilePath):
            try:
                FileMTimes[NormalizedPath] = os.path.getmtime(FilePath);

            except OSError:
                pass;

def IsRSActivelyConnected() -> (bool):
    return (RSConnected and ((time.time() - LastRSContactTime) < 10.0));

def ConsumePendingRSClear() -> (bool):
    global PendingRSClear;

    with SuppressionLock:
        if PendingRSClear:
            PendingRSClear = False;

            return True;

        return False;

def ClearProjectDirectory(TargetBasePath: Optional[str] = None, NotifyRS: bool = False) -> (int):
    global KnownDirectories, PendingRSClear;

    TargetDir: str = TargetBasePath or BasePath;
    ClearedCount: int = 0;

    if os.path.isdir(TargetDir):
        for EntryName in os.listdir(TargetDir):
            if (EntryName in IgnoredDirectories):
                continue;

            EntryPath: str = os.path.join(TargetDir, EntryName);

            if SendToRecycleBin(EntryPath):
                ClearedCount += 1;

    with SuppressionLock:
        FileHashes.clear();
        FileMTimes.clear();
        KnownDirectories.clear();
        SuppressedHashes.clear();

        if NotifyRS and IsRSActivelyConnected():
            PendingRSClear = True;

    if NotifyRS and IsRSActivelyConnected():
        ChangeEventsQueue.AddEvent(Action = 'clear_project', Path = '__all__');
        print(f'[Silicon Server] Cleared {ClearedCount} top-level item(s) from {TargetDir} and notified connected RS client to clear.');

    else:
        print(f'[Silicon Server] Cleared {ClearedCount} top-level item(s) from {TargetDir} (moved to Recycle Bin).');

    return ClearedCount;

def InferScriptTypeFromFileName(FileName: str) -> (Optional[str]):
    LowerName: str = FileName.lower();

    if '.client.' in LowerName:
        return 'client';

    if '.server.' in LowerName:
        return 'server';

    if '.shared.' in LowerName:
        return 'shared';

    return None;

def ResolvePropertiesFileTarget(ObjectDir: str) -> (Tuple[str, str, bool]):
    ConfiguredExt: str = Settings.get('PropertiesFileExtension', 'yaml').lower();
    PrefExt: str = 'yaml' if ('y' in ConfiguredExt) else 'json';
    AltExt: str = 'json' if (PrefExt == 'yaml') else 'yaml';

    PrefName: str = f'{PN}.{PrefExt}';
    AltName: str = f'{PN}.{AltExt}';

    PrefPath: str = os.path.join(ObjectDir, PrefName);
    AltPath: str = os.path.join(ObjectDir, AltName);

    PrefExists: bool = os.path.isfile(PrefPath);
    AltExists: bool = os.path.isfile(AltPath);

    if (PrefExists and AltExists):
        try:
            os.remove(AltPath);

        except Exception:
            pass;

        return (PrefPath, PrefName, (PrefExt == 'yaml'));

    elif AltExists:
        return (AltPath, AltName, (AltExt == 'yaml'));

    else:
        return (PrefPath, PrefName, (PrefExt == 'yaml'));

def WatchLoop() -> (None):
    global KnownDirectories;

    LastRibbonCheckTime: float = 0.0;

    while WatcherRunning:
        try:
            NowTime: float = time.time();

            if ((NowTime - LastRibbonCheckTime) >= 1.5):
                LastRibbonCheckTime = NowTime;
                SetSiliconRibbonTabVisible((Settings.get('ShowRibbonTab', True) is not False), True);

            CurrentFiles: Set[str] = set();
            CurrentDirs: Set[str] = set();

            for RootPath, Dirs, Files in os.walk(BasePath):
                Dirs[:] = [Directory for Directory in Dirs if (Directory not in IgnoredDirectories) and (not IsPathIgnored(os.path.relpath(os.path.join(RootPath, Directory), BasePath)))];
                RelDir: str = os.path.relpath(RootPath, BasePath).replace('\\', '/');

                if (RelDir != '.') and (not IsPathIgnored(RelDir)):
                    CurrentDirs.add(RelDir);

                for FileName in Files:
                    FilePath: str = os.path.join(RootPath, FileName);
                    RelPath: str = os.path.relpath(FilePath, BasePath).replace('\\', '/');

                    if IsPathIgnored(RelPath):
                        continue;

                    IsProperties: bool = (FileName == PropertiesFileName) or (FileName == 'Properties.json') or (FileName == 'Properties.yaml') or (FileName == '__Properties__.yaml');
                    IsSource: bool = FileName.startswith('Source.') or FileName.startswith('__Source__.') or (FileName.endswith('.luau') or FileName.endswith('.lua'));

                    if not (IsProperties or IsSource):
                        continue;

                    if IsProperties:
                        ResolvedPropsPath: str = ResolvePropertiesFileTarget(RootPath)[0];

                        if (FilePath != ResolvedPropsPath) and os.path.isfile(ResolvedPropsPath):
                            continue;

                    CurrentFiles.add(RelPath);

                    try:
                        MTime: float = os.path.getmtime(FilePath);

                    except OSError:
                        continue;

                    if (RelPath not in FileMTimes) or (MTime > FileMTimes[RelPath]):
                        try:
                            with open(FilePath, 'r', encoding = 'utf-8', errors = 'replace') as Handle:
                                FileContent: str = Handle.read();

                        except OSError:
                            continue;

                        NewHash: str = ComputeSHA256(FileContent);
                        OldHash: Optional[str] = FileHashes.get(RelPath);

                        FileMTimes[RelPath] = MTime;

                        if (NewHash != OldHash):
                            with SuppressionLock:
                                if (NewHash in SuppressedHashes):
                                    SuppressedHashes.remove(NewHash);
                                    FileHashes[RelPath] = NewHash;

                                    continue;

                            FileHashes[RelPath] = NewHash;

                            ObjectRelPath: str = RelDir;

                            if (ObjectRelPath == '.'):
                                continue;

                            if IsProperties:
                                try:
                                    ParsedPropertiesData: Dict[str, Any] = yaml.safe_load(FileContent) or { };
                                    ExtractedClassName: str = ParsedPropertiesData.get('ClassName', 'Folder');
                                    ExtractedProperties: Dict[str, Any] = ParsedPropertiesData.get('Properties', { });
                                    ExtractedAttributes: Dict[str, Any] = ParsedPropertiesData.get('Attributes', { });
                                    ExtractedTags: List[str] = ParsedPropertiesData.get('Tags', [ ]);

                                    print(f'[Silicon Watcher] Local property change: {ObjectRelPath} ({ExtractedClassName})');
                                    ChangeEventsQueue.AddEvent(
                                        Action     = 'update_properties',
                                        Path       = ObjectRelPath,
                                        ClassName  = ExtractedClassName,
                                        FileHash   = NewHash,
                                        Properties = ExtractedProperties,
                                        Attributes = ExtractedAttributes,
                                        Tags       = ExtractedTags,
                                    );

                                except Exception as ParseError:
                                    print(f'[Silicon Watcher] Error parsing {RelPath}: {ParseError}');

                            elif IsSource:
                                ScriptType: Optional[str] = InferScriptTypeFromFileName(FileName);
                                print(f'[Silicon Watcher] Local source change: {ObjectRelPath} ({ScriptType or "source"})');
                                ChangeEventsQueue.AddEvent(
                                    Action     = 'update_source',
                                    Path       = ObjectRelPath,
                                    Source     = FileContent,
                                    FileHash   = NewHash,
                                    ScriptType = ScriptType,
                                );

            with SuppressionLock:
                DeletedFiles: Set[str] = (set(FileHashes.keys()) - CurrentFiles);

                for DeletedPath in DeletedFiles:
                    del FileHashes[DeletedPath];

                    if (DeletedPath in FileMTimes):
                        del FileMTimes[DeletedPath];

                DeletedDirs: Set[str] = (KnownDirectories - CurrentDirs);

                for DeletedDir in DeletedDirs:
                    print(f'[Silicon Watcher] Local delete: {DeletedDir}');
                    ChangeEventsQueue.AddEvent('delete', DeletedDir);

                NewDirs: Set[str] = (CurrentDirs - KnownDirectories);

                for NewDir in NewDirs:
                    print(f'[Silicon Watcher] Local directory create: {NewDir}');
                    ChangeEventsQueue.AddEvent('create', NewDir);

                KnownDirectories = CurrentDirs;

        except Exception as LoopError:
            print(f'[Silicon Watcher] Error in scan loop: {LoopError}');

        time.sleep(0.05);

def StartWatcher() -> (None):
    global KnownDirectories;

    KnownDirectories.clear();

    for RootPath, Dirs, Files in os.walk(BasePath):
        Dirs[:] = [Directory for Directory in Dirs if (Directory not in IgnoredDirectories) and (not IsPathIgnored(os.path.relpath(os.path.join(RootPath, Directory), BasePath)))];
        RelDir: str = os.path.relpath(RootPath, BasePath).replace('\\', '/');

        if (RelDir != '.') and (not IsPathIgnored(RelDir)):
            KnownDirectories.add(RelDir);

        for FileName in Files:
            FilePath: str = os.path.join(RootPath, FileName);
            RelPath: str = os.path.relpath(FilePath, BasePath).replace('\\', '/');

            if IsPathIgnored(RelPath):
                continue;

            IsProperties: bool = (FileName == PropertiesFileName) or (FileName == 'Properties.json') or (FileName == 'Properties.yaml') or (FileName == '__Properties__.yaml');
            IsSource: bool = FileName.startswith('Source.') or FileName.startswith('__Source__.') or (FileName.endswith('.luau') or FileName.endswith('.lua'));

            if not (IsProperties or IsSource):
                continue;

            if IsProperties:
                ResolvedPropsPath: str = ResolvePropertiesFileTarget(RootPath)[0];

                if (FilePath != ResolvedPropsPath) and os.path.isfile(ResolvedPropsPath):
                    continue;

            FileHashes[RelPath] = ComputeFileSHA256(FilePath);
            FileMTimes[RelPath] = os.path.getmtime(FilePath);

    WatcherThread: Thread = Thread(target = WatchLoop, daemon = True);
    WatcherThread.start();
    print(f'[Silicon Server] Connected to workspace directory: {BasePath}');
    print(f'[Silicon Watcher] Monitoring {len(KnownDirectories)} object folder(s) across all game services and directories...');



def GetHandler(POSTEnabled: Optional[bool] = True, GETEnabled: Optional[bool] = True, StopAfterOneIteration: Optional[bool] = True):
    class RequestHandler(BaseHTTPRequestHandler):
        def log_message(self, Format: str, *Arguments: Any) -> (None):
            pass;

        def do_POST(self) -> (None):
            global Settings, RSConnected, LastRSContactTime;

            ParsedURL = urllib.parse.urlparse(self.path);
            PathName: str = (ParsedURL.path);
            UserAgent: str = (self.headers.get('User-Agent') or '');
            IsCLIRequest: bool = ('python-requests' in UserAgent.lower()) or (PathName in ('/stop', '/shutdown'));

            if not IsCLIRequest:
                LastRSContactTime = time.time();

                if not RSConnected:
                    RSConnected = True;
                    print(f'[Silicon Server] RS connected successfully from {self.client_address[0]}!');

            try:
                if not POSTEnabled:
                    self.send_error(405, 'POST method not allowed');
                    return;

                ContentLength: int = int(self.headers.get('Content-Length', 0));
                RawBody: bytes = self.rfile.read(ContentLength) if (ContentLength > 0) else b'';

                if (PathName in ('/synchronization', '/sync')) or PathName.endswith('/synchronization') or PathName.endswith('/sync') or (PathName in ('/synchronization_all', '/sync_all')):
                    BodyString: str = RawBody.decode('utf-8', errors = 'replace');
                    SynchronizationData: Dict[str, Any] = json.loads(BodyString) if (BodyString and BodyString.strip()) else { };

                    ObjectsList: List[Dict[str, Any]] = SynchronizationData.get('objects') or SynchronizationData.get('scripts') or [ ];

                    if ObjectsList:
                        print(f'[Silicon Server] RS exported batch of {len(ObjectsList)} object(s) -> Writing to disk...');

                        SavedCount: int = 0;

                        for ObjectItem in ObjectsList:
                            RelativePath: str = ObjectItem.get('path', '');
                            ClassName: str = ObjectItem.get('className', 'Folder');
                            Properties: Dict[str, Any] = ObjectItem.get('properties', { });
                            Attributes: Dict[str, Any] = ObjectItem.get('attributes', { });
                            Tags: List[str] = ObjectItem.get('tags', [ ]);
                            Source: Optional[str] = ObjectItem.get('source');
                            ScriptType: Optional[str] = ObjectItem.get('scriptType');

                            if not RelativePath or IsPathIgnored(RelativePath):
                                continue;

                            ObjectDir: str = os.path.join(BasePath, RelativePath);
                            os.makedirs(ObjectDir, exist_ok = True);

                            PropertiesPayload: Dict[str, Any] = {
                                'ClassName' : ClassName,
                                'Properties': Properties,
                                'Attributes': Attributes,
                                'Tags'      : Tags,
                            };
                            PropertiesFilePath, _, IsActualYAML = ResolvePropertiesFileTarget(ObjectDir);
                            PropertiesContent: str = (
                                yaml.dump(PropertiesPayload, default_flow_style = False, allow_unicode = True, sort_keys = False)
                                if IsActualYAML
                                else json.dumps(PropertiesPayload, indent = 2)
                            );

                            with open(PropertiesFilePath, 'w', encoding = 'utf-8') as PropsFile:
                                PropsFile.write(PropertiesContent);

                            MarkRSWrite(PropertiesFilePath, ComputeSHA256(PropertiesContent));

                            if (Source is not None):
                                ResolvedScriptType: str = ScriptType or (
                                    'client' if (ClassName == 'LocalScript')
                                    else ('server' if (ClassName == 'Script') else 'shared')
                                );
                                TargetSourceFileName: str = f'Source.{ResolvedScriptType}.luau';
                                TargetSourceFilePath: str = os.path.join(ObjectDir, TargetSourceFileName);

                                for ExistingFile in os.listdir(ObjectDir):
                                    if (ExistingFile.startswith('Source.') or ExistingFile.startswith('__Source__.')) and (ExistingFile != TargetSourceFileName):
                                        try:
                                            os.remove(os.path.join(ObjectDir, ExistingFile));
                                        except OSError:
                                            pass;

                                with open(TargetSourceFilePath, 'w', encoding = 'utf-8') as SourceFile:
                                    SourceFile.write(Source);

                                MarkRSWrite(TargetSourceFilePath, ComputeSHA256(Source));

                            else:
                                for ExistingFile in os.listdir(ObjectDir):
                                    if ExistingFile.startswith('Source.') or ExistingFile.startswith('__Source__.'):
                                        try:
                                            os.remove(os.path.join(ObjectDir, ExistingFile));
                                        except OSError:
                                            pass;

                            SavedCount += 1;

                        print(f'[Silicon Server] Successfully saved batch of {SavedCount} object(s) from RS to local disk.');
                        ResponsePayload: bytes = json.dumps({ 'success': True, 'count': SavedCount }).encode('utf-8');
                        self.send_response(200);
                        self.send_header('Content-Type', 'application/json');
                        self.send_header('Content-Length', str(len(ResponsePayload)));
                        self.end_headers();
                        self.wfile.write(ResponsePayload);

                        return;

                    Action: str = SynchronizationData.get('action', 'update');

                    if (Action in ('finalize_synchronization', 'finalize_sync')):
                        IsChunk: bool = SynchronizationData.get('is_chunk', False);
                        IsFinal: bool = SynchronizationData.get('is_final', True);
                        ChunkPaths: List[str] = SynchronizationData.get('received_paths', [ ]);

                        if not hasattr(self.server, 'AccumulatedPaths'):
                            self.server.AccumulatedPaths = set();

                        if IsChunk:
                            self.server.AccumulatedPaths.update(ChunkPaths);

                            if not IsFinal:
                                ResponsePayload: bytes = json.dumps({ 'success': True, 'accumulated': len(self.server.AccumulatedPaths) }).encode('utf-8');
                                self.send_response(200);
                                self.send_header('Content-Type', 'application/json');
                                self.send_header('Content-Length', str(len(ResponsePayload)));
                                self.end_headers();
                                self.wfile.write(ResponsePayload);

                                return;

                            AllExportedPaths: Set[str] = self.server.AccumulatedPaths;
                            self.server.AccumulatedPaths = set();

                        else:
                            AllExportedPaths: Set[str] = set(ChunkPaths);

                        PrunedCount: int = 0;

                        for RootPath, Dirs, Files in os.walk(BasePath, topdown = False):
                            Dirs[:] = [Directory for Directory in Dirs if (Directory not in IgnoredDirectories) and (not IsPathIgnored(os.path.relpath(os.path.join(RootPath, Directory), BasePath)))];
                            RelDir = os.path.relpath(RootPath, BasePath).replace('\\', '/');

                            if (RelDir == '.') or IsPathIgnored(RelDir):
                                continue;

                            if (RelDir not in AllExportedPaths):
                                print(f'[Silicon Server] Pruning local object folder (not present in RS): {RelDir}');
                                SendToRecycleBin(RootPath);
                                PrunedCount += 1;

                        if (PrunedCount > 0):
                            print(f'[Silicon Server] Pruned {PrunedCount} object folder(s) from local disk to match RS.');

                        print(f'[Silicon Server] Synchronization finalized: {len(AllExportedPaths)} object(s) synchronized.');
                        ResponsePayload = json.dumps({ 'success': True, 'pruned': PrunedCount }).encode('utf-8');
                        self.send_response(200);
                        self.send_header('Content-Type', 'application/json');
                        self.send_header('Content-Length', str(len(ResponsePayload)));
                        self.end_headers();
                        self.wfile.write(ResponsePayload);

                        return;

                    RelativePath = SynchronizationData.get('path', '');

                    if not RelativePath or IsPathIgnored(RelativePath):
                        if not RelativePath:
                            self.send_error(400, 'Path is required');
                            return;

                        ResponsePayload = json.dumps({ 'success': True, 'ignored': True }).encode('utf-8');
                        self.send_response(200);
                        self.send_header('Content-Type', 'application/json');
                        self.send_header('Content-Length', str(len(ResponsePayload)));
                        self.end_headers();
                        self.wfile.write(ResponsePayload);

                        return;

                    FullTargetDir: str = os.path.join(BasePath, RelativePath);

                    if (Action == 'delete'):
                        print(f'[Silicon Server] RS requested delete: {RelativePath} -> Moving to Recycle Bin');
                        SendToRecycleBin(FullTargetDir);

                        with SuppressionLock:
                            KeysToDelete: List[str] = [K for K in FileHashes if K.startswith(RelativePath)];
                            for K in KeysToDelete:
                                del FileHashes[K];
                                if (K in FileMTimes):
                                    del FileMTimes[K];

                        ResponsePayload = json.dumps({ 'success': True, 'action': 'deleted' }).encode('utf-8');
                        self.send_response(200);
                        self.send_header('Content-Type', 'application/json');
                        self.send_header('Content-Length', str(len(ResponsePayload)));
                        self.end_headers();
                        self.wfile.write(ResponsePayload);

                        return;

                    if (Action == 'chunk'):
                        ChunkIndex: int = int(SynchronizationData.get('chunk_index', 1));
                        TotalChunks: int = int(SynchronizationData.get('total_chunks', 1));
                        ChunkSource: str = SynchronizationData.get('chunk_source', '');

                        if (RelativePath not in ChunkBuffers):
                            ChunkBuffers[RelativePath] = { };

                        ChunkBuffers[RelativePath][ChunkIndex] = ChunkSource;

                        if (len(ChunkBuffers[RelativePath]) >= TotalChunks):
                            FullSource: str = ''.join(ChunkBuffers[RelativePath][Index] for Index in sorted(ChunkBuffers[RelativePath]));
                            del ChunkBuffers[RelativePath];

                            if os.path.isfile(FullTargetDir):
                                try:
                                    os.remove(FullTargetDir);
                                except OSError:
                                    pass;

                            os.makedirs(FullTargetDir, exist_ok = True);

                            PropertiesPayload = {
                                'ClassName' : SynchronizationData.get('className', 'ModuleScript'),
                                'Properties': SynchronizationData.get('properties', { }),
                                'Attributes': SynchronizationData.get('attributes', { }),
                                'Tags'      : SynchronizationData.get('tags', [ ]),
                            };
                            PropertiesFilePath, _, IsActualYAML = ResolvePropertiesFileTarget(FullTargetDir);
                            PropertiesContent = (
                                yaml.dump(PropertiesPayload, default_flow_style = False, allow_unicode = True, sort_keys = False)
                                if IsActualYAML
                                else json.dumps(PropertiesPayload, indent = 2)
                            );

                            with open(PropertiesFilePath, 'w', encoding = 'utf-8') as PropsFile:
                                PropsFile.write(PropertiesContent);

                            MarkRSWrite(PropertiesFilePath, ComputeSHA256(PropertiesContent));

                            ResolvedScriptType = SynchronizationData.get('scriptType') or (
                                'client' if (SynchronizationData.get('className') == 'LocalScript')
                                else ('server' if (SynchronizationData.get('className') == 'Script') else 'shared')
                            );
                            TargetSourceFileName = f'Source.{ResolvedScriptType}.luau';
                            TargetSourceFilePath = os.path.join(FullTargetDir, TargetSourceFileName);

                            with open(TargetSourceFilePath, 'w', encoding = 'utf-8') as OutFile:
                                OutFile.write(FullSource);

                            FullHash: str = ComputeSHA256(FullSource);
                            MarkRSWrite(TargetSourceFilePath, FullHash);

                            print(f'[Silicon Server] RS synchronization (chunked {TotalChunks} parts) -> Disk: {RelativePath} ({len(FullSource)} bytes)');
                            ResponsePayload = json.dumps({ 'success': True, 'hash': FullHash }).encode('utf-8');

                        else:
                            ResponsePayload = json.dumps({ 'success': True, 'chunk': ChunkIndex, 'total': TotalChunks }).encode('utf-8');

                        self.send_response(200);
                        self.send_header('Content-Type', 'application/json');
                        self.send_header('Content-Length', str(len(ResponsePayload)));
                        self.end_headers();
                        self.wfile.write(ResponsePayload);

                        return;

                    if os.path.isfile(FullTargetDir):
                        try:
                            os.remove(FullTargetDir);
                        except OSError:
                            pass;

                    os.makedirs(FullTargetDir, exist_ok = True);

                    ClassName = SynchronizationData.get('className', 'Folder');
                    Properties = SynchronizationData.get('properties', { });
                    Attributes = SynchronizationData.get('attributes', { });
                    Tags = SynchronizationData.get('tags', [ ]);
                    Source = SynchronizationData.get('source');
                    ScriptType = SynchronizationData.get('scriptType');

                    PropertiesPayload = {
                        'ClassName' : ClassName,
                        'Properties': Properties,
                        'Attributes': Attributes,
                        'Tags'      : Tags,
                    };
                    PropertiesFilePath, _, IsActualYAML = ResolvePropertiesFileTarget(FullTargetDir);
                    PropertiesContent = (
                        yaml.dump(PropertiesPayload, default_flow_style = False, allow_unicode = True, sort_keys = False)
                        if IsActualYAML
                        else json.dumps(PropertiesPayload, indent = 2)
                    );

                    with open(PropertiesFilePath, 'w', encoding = 'utf-8') as PropsFile:
                        PropsFile.write(PropertiesContent);

                    MarkRSWrite(PropertiesFilePath, ComputeSHA256(PropertiesContent));

                    if (Source is not None):
                        ResolvedScriptType = ScriptType or (
                            'client' if (ClassName == 'LocalScript')
                            else ('server' if (ClassName == 'Script') else 'shared')
                        );
                        TargetSourceFileName = f'Source.{ResolvedScriptType}.luau';
                        TargetSourceFilePath = os.path.join(FullTargetDir, TargetSourceFileName);

                        with open(TargetSourceFilePath, 'w', encoding = 'utf-8') as SourceFile:
                            SourceFile.write(Source);

                        MarkRSWrite(TargetSourceFilePath, ComputeSHA256(Source));

                    print(f'[Silicon Server] RS synchronization -> Disk: {RelativePath} ({ClassName})');
                    ResponsePayload = json.dumps({ 'success': True }).encode('utf-8');
                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(ResponsePayload)));
                    self.end_headers();
                    self.wfile.write(ResponsePayload);

                    return;

                if (PathName == '/settings') or PathName.endswith('/settings'):
                    SettingsData: bytes = RawBody;
                    if IsDataGZipped(SettingsData):
                        with gzip.GzipFile(fileobj = io.BytesIO(SettingsData), mode = 'rb') as File:
                            SettingsData = File.read();

                    BodyString: str = SettingsData.decode('utf-8', errors = 'replace');
                    NewSettings: Dict[str, Any] = json.loads(BodyString) if (BodyString and BodyString.strip()) else { };

                    if 'ConflictMode' in NewSettings:
                        Settings['ConflictMode'] = NewSettings['ConflictMode'];

                    if 'SynchronizeAllDescendants' in NewSettings:
                        Settings['SynchronizeAllDescendants'] = (str(NewSettings['SynchronizeAllDescendants']).lower() in ('true', '1'));
                        Settings['SyncAllDescendants'] = Settings['SynchronizeAllDescendants'];

                    elif 'SyncAllDescendants' in NewSettings:
                        Settings['SynchronizeAllDescendants'] = (str(NewSettings['SyncAllDescendants']).lower() in ('true', '1'));
                        Settings['SyncAllDescendants'] = Settings['SynchronizeAllDescendants'];

                    if 'InitialSyncFromRS' in NewSettings:
                        Settings['InitialSyncFromRS'] = (str(NewSettings['InitialSyncFromRS']).lower() in ('true', '1'));

                    if 'ShowRibbonTab' in NewSettings:
                        RibbonVisible: bool = (str(NewSettings['ShowRibbonTab']).lower() in ('true', '1'));
                        PreviousRibbonVisible: Optional[bool] = Settings.get('ShowRibbonTab');
                        Settings['ShowRibbonTab'] = RibbonVisible;
                        SetSiliconRibbonTabVisible(RibbonVisible, (PreviousRibbonVisible == RibbonVisible));

                    ShouldClearRS: bool = ConsumePendingRSClear();
                    ResponsePayload = json.dumps({ 'success': True, 'clearRS': ShouldClearRS }).encode('utf-8');
                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(ResponsePayload)));
                    self.end_headers();
                    self.wfile.write(ResponsePayload);

                    return;

                if (PathName in ('/clear', '/clear_project')) or PathName.endswith('/clear') or PathName.endswith('/clear_project'):
                    ClearBodyText: str = RawBody.decode('utf-8', errors = 'replace') if RawBody else '';
                    ClearRequestData: Dict[str, Any] = { };

                    if ClearBodyText and ClearBodyText.strip():
                        try:
                            ClearRequestData = json.loads(ClearBodyText) or { };
                        except Exception:
                            ClearRequestData = { };

                    Origin: str = str(ClearRequestData.get('origin', 'IDE')).upper();
                    ShouldNotifyRS: bool = (Origin != 'RS');
                    ClearedItems: int = ClearProjectDirectory(NotifyRS = ShouldNotifyRS);
                    ClearPayload: bytes = json.dumps({ 'Status': 'Cleared', 'ClearedCount': ClearedItems }).encode('utf-8');
                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(ClearPayload)));
                    self.end_headers();
                    self.wfile.write(ClearPayload);

                    return;

                if (PathName in ('/stop', '/shutdown')) or PathName.endswith('/stop') or PathName.endswith('/shutdown'):
                    StopPayload: bytes = json.dumps({ 'Status': 'Stopping' }).encode('utf-8');
                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(StopPayload)));
                    self.end_headers();
                    self.wfile.write(StopPayload);

                    Thread(target = StopHTTPServer, daemon = True).start();

                    return;

                OK: bool = True;

                StatusHeader: Dict[str, str] = Settings.get('StatusHeader', { });
                SettingsHeader: Dict[str, str] = Settings.get('SettingsHeader', { });
                DataHeader: Dict[str, str] = Settings.get('DataHeader', { });
                LIVEHeader: Dict[str, str] = Settings.get('LIVEHeader', { });

                TypeHeaderName: str = list(DataHeader.keys())[0] if DataHeader else 'Request-Type';
                FrequencyHeaderName: str = list(LIVEHeader.keys())[0] if LIVEHeader else 'Request-Frequency';

                RequestType: str = self.headers.get(TypeHeaderName, '').lower();
                ExpectedStatusType: str = (StatusHeader.get(TypeHeaderName, 'getstatus')).lower();
                ExpectedSettingsType: str = (SettingsHeader.get(TypeHeaderName, 'postgetsettings')).lower();
                ExpectedDataType: str = (DataHeader.get(TypeHeaderName, 'postgetdata')).lower();
                LiveValue: str = (LIVEHeader.get(FrequencyHeaderName, 'live')).lower();

                RequestFrequency: bool = ((self.headers.get(FrequencyHeaderName, '').lower()) == LiveValue);

                Data: bytes = RawBody;

                if IsDataGZipped(Data):
                    with gzip.GzipFile(fileobj = io.BytesIO(Data), mode = 'rb') as File:
                        Data = File.read();

                if (RequestType == ExpectedStatusType) or (not RequestType and not Data):
                    AliveResponse['Version'] = Settings.get('Version', '0.0.0');
                    StatusPayload: bytes = json.dumps(AliveResponse).encode('utf-8');
                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(StatusPayload)));
                    self.end_headers();
                    self.wfile.write(StatusPayload);

                    return;

                ParsedData: Dict[str, Any] = { };

                if Data and Data.strip():
                    try:
                        ParsedData = json.loads(Data.decode('utf-8'));
                    except Exception:
                        pass;

                if (RequestType == ExpectedSettingsType):
                    Settings = ParsedData;

                elif (RequestType == ExpectedDataType):
                    Index: int = ParsedData['Index'];
                    Total: int = ParsedData['Total'];
                    Chunk: str = ParsedData['Chunk'];

                    Chunks[Index] = Chunk;

                    print(f'Successfully received data-chunk ({Index}/{Total})!');

                    if (len(Chunks) >= Total):
                        if StopAfterOneIteration and (Settings.get('CleanUpBeforeImportInIDE', False) or Settings.get('CleanUpBeforeImportInVSC', False)):
                            DeletePath(BasePath);
                            print(f'Successfully removed all descendants of {BasePath} before importing!');

                        Import(json.loads(''.join(Chunks[i] for i in sorted(Chunks))), BasePath, RequestFrequency);
                        Chunks.clear();

                        print('Successfully reconstructed hierarchy!');

                else:
                    self.send_error(400, f'\'{TypeHeaderName}\' Header either not passed or incorrect ({RequestType}). Please try again using {DataHeader}, {SettingsHeader} or {StatusHeader}.');
                    OK = False;

                if OK:
                    self.send_response(200);
                    self.end_headers();

            except Exception as Error:
                self.send_error(500, 'Unexpected error');
                LogException(Error, 'reconstruct hierarchy!');

            if StopAfterOneIteration:
                StopHTTPServer();

        def do_GET(self) -> (None):
            global Settings, RSConnected, LastRSContactTime;

            ParsedURL = urllib.parse.urlparse(self.path);
            PathName: str = (ParsedURL.path);
            UserAgent: str = (self.headers.get('User-Agent') or '');
            IsCLIRequest: bool = ('python-requests' in UserAgent.lower()) or (PathName in ('/stop', '/shutdown'));

            if not IsCLIRequest:
                LastRSContactTime = time.time();

                if not RSConnected:
                    RSConnected = True;
                    print(f'[Silicon Server] RS connected successfully from {self.client_address[0]}!');

            try:
                if not GETEnabled:
                    self.send_error(405, 'GET method not allowed');

                    return;

                QueryParams: Dict[str, List[str]] = urllib.parse.parse_qs(ParsedURL.query);

                if (PathName == '/changes') or PathName.endswith('/changes'):
                    SinceID: int = int(QueryParams.get('since', [0])[0]);
                    Timeout: float = float(QueryParams.get('timeout', [5.0])[0]);
                    Timeout = max(0.0, min(15.0, Timeout));

                    RawEventsList, LatestID = ChangeEventsQueue.GetEventsSince(SinceID, Timeout);
                    EventsList: List[Dict[str, Any]] = [ ];

                    for EventItem in RawEventsList:
                        if (EventItem.get('action') == 'clear_project'):
                            if ConsumePendingRSClear():
                                EventsList.append(EventItem);
                        else:
                            EventsList.append(EventItem);

                    if EventsList:
                        PathsSummary: str = ', '.join([str(E.get('path', 'unknown')) for E in EventsList[:3]]);
                        if (len(EventsList) > 3):
                            PathsSummary += f' and {len(EventsList) - 3} more';
                        print(f'[Silicon Server] Dispatched {len(EventsList)} change event(s) to RS: <{PathsSummary}>');

                    ChangesResponse: Dict[str, Any] = {
                        'events'  : EventsList,
                        'latestId': LatestID,
                    };
                    PayloadBytes: bytes = json.dumps(ChangesResponse).encode('utf-8');

                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(PayloadBytes)));
                    self.send_header('Access-Control-Allow-Origin', '*');
                    self.end_headers();
                    self.wfile.write(PayloadBytes);

                    return;

                if (PathName == '/settings') or PathName.endswith('/settings'):
                    SettingsPayload: bytes = json.dumps(Settings).encode('utf-8');

                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(SettingsPayload)));
                    self.end_headers();
                    self.wfile.write(SettingsPayload);

                    return;

                if (PathName == '/status') or PathName.endswith('/status'):
                    StatusPayload: bytes = json.dumps(AliveResponse).encode('utf-8');

                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(StatusPayload)));
                    self.end_headers();
                    self.wfile.write(StatusPayload);

                    return;

                if (PathName in ('/clear', '/clear_project')) or PathName.endswith('/clear') or PathName.endswith('/clear_project'):
                    ClearedItems: int = ClearProjectDirectory(NotifyRS = True);
                    ClearPayload: bytes = json.dumps({ 'Status': 'Cleared', 'ClearedCount': ClearedItems }).encode('utf-8');

                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(ClearPayload)));
                    self.end_headers();
                    self.wfile.write(ClearPayload);

                    return;

                if (PathName in ('/stop', '/shutdown')) or PathName.endswith('/stop') or PathName.endswith('/shutdown'):
                    StopPayload: bytes = json.dumps({ 'Status': 'Stopping' }).encode('utf-8');

                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.send_header('Content-Length', str(len(StopPayload)));
                    self.end_headers();
                    self.wfile.write(StopPayload);

                    Thread(target = StopHTTPServer, daemon = True).start();

                    return;

                OK: bool = True;

                StatusHeader: Dict[str, str] = Settings.get('StatusHeader', { });
                SettingsHeader: Dict[str, str] = Settings.get('SettingsHeader', { });
                DataHeader: Dict[str, str] = Settings.get('DataHeader', { });
                TypeHeaderName: str = list(DataHeader.keys())[0] if DataHeader else 'Request-Type';

                RequestType: str = self.headers.get(TypeHeaderName, '').lower();
                ExpectedStatusType: str = (StatusHeader.get(TypeHeaderName, 'getstatus')).lower();
                ExpectedSettingsType: str = (SettingsHeader.get(TypeHeaderName, 'postgetsettings')).lower();
                ExpectedDataType: str = (DataHeader.get(TypeHeaderName, 'postgetdata')).lower();

                Response: Optional[Dict[str, Any]] = None;

                if (RequestType == ExpectedSettingsType):
                    Response = Settings;

                elif (RequestType == ExpectedDataType) or (PathName in ('/export', '/files')):
                    print('[Silicon Server] RS requested full import: Gathering local objects from disk...');
                    Response = Export(Script);
                    FilesCount: int = len(Response.get('files', [ ])) if isinstance(Response, dict) else 0;
                    print(f'[Silicon Server] Sent {FilesCount} object(s) to RS.');

                elif (RequestType == ExpectedStatusType) or (not RequestType and PathName in ('/', '')):
                    Response = AliveResponse;

                else:
                    self.send_error(400, f'\'{TypeHeaderName}\' Header either not passed or incorrect ({RequestType}). Please try again using {DataHeader}, {SettingsHeader} or {StatusHeader}.');
                    OK = False;

                if OK:
                    self.send_response(200);
                    self.send_header('Content-Type', 'application/json');
                    self.end_headers();

                if Response is None:
                    Response = NoDataAvailableResponse;

                self.wfile.write(json.dumps(Response).encode('utf-8'));

            except Exception as Error:
                self.send_error(500, 'Unexpected error');
                LogException(Error, 'send hierarchy data over!');

            if StopAfterOneIteration:
                StopHTTPServer();

    return RequestHandler;



def LogException(Error: Exception, ErrorDescription: str) -> (None):
    print(f'An error occurred whilst trying to {ErrorDescription}\n');
    print(f'Exception Type: {(type(Error).__name__)}');
    print(f'Exception Message: {str(Error)}\n');
    print(''.join(traceback.format_exception(type(Error), Error, (Error.__traceback__))));

def IsDataGZipped(Data: bytes) -> (bool):
    return (Data[:2] == b'\x1f\x8b');

def DeletePath(Path: str) -> (None):
    if os.path.isdir(Path):
        shutil.rmtree(Path);

    else:
        os.remove(Path);

def StopHTTPServer() -> (None):
    global WatcherRunning;
    WatcherRunning = False;

    if Server:
        try:
            Server.shutdown();
            print('Successfully stopped the running server!');
            sys.exit(0);

        except Exception as Error:
            LogException(Error, 'stop the running server!');
            sys.exit(1);

    else:
        print('The server tried to stop running, yet it already had.');
        sys.exit(0);

def IsHTTPServerRunning(ServerURL: str) -> (bool):
    try:
        StatusHeader: Dict[str, str] = Settings.get('StatusHeader', { 'Request-Type': 'GETStatus' });
        POSTResponse: requests.Response = requests.post(ServerURL, headers = StatusHeader, timeout = 1.0);
        GETResponse: requests.Response = requests.get(ServerURL, headers = StatusHeader, timeout = 1.0);

        return (((POSTResponse.status_code) == 200) or ((GETResponse.status_code) == 200));

    except (requests.exceptions.RequestException):
        pass;

    except Exception as Error:
        LogException(Error, 'verify if the server is running!');

    return False;

HasPrintedSettingsAccess: bool = False;

def LoadSettings(ExplicitSettingsPath: Optional[str] = None) -> (Dict[str, Any]):
    global HasPrintedSettingsAccess;

    SettingsFilePath: str = '';

    if ExplicitSettingsPath and os.path.isfile(ExplicitSettingsPath):
        SettingsFilePath = os.path.abspath(ExplicitSettingsPath);

    elif os.path.exists(os.path.join(ScriptPath, 'Settings.yaml')):
        SettingsFilePath = os.path.join(ScriptPath, 'Settings.yaml');

    elif os.path.exists(os.path.join(ScriptPath, 'silicon.yaml')):
        SettingsFilePath = os.path.join(ScriptPath, 'silicon.yaml');

    else:
        SettingsFilePath = os.path.join(SiliconScriptDir, 'Settings.yaml');

    try:
        with open(SettingsFilePath, 'r') as File:
            SettingsData: Dict[str, Any] = yaml.safe_load(File);

            if not HasPrintedSettingsAccess:
                HasPrintedSettingsAccess = True;
                print('Successfully accessed the configuration file\'s data!');

            return SettingsData;

    except Exception as Error:
        LogException(Error, 'access the configuration file\'s data!');

        return { };


Settings: Dict[str, Any] = LoadSettings();
PN: str = Settings.get('PropertiesName', 'Properties');
SN: str = Settings.get('SourceName', 'Source');
PropertiesFileExtension: str = Settings.get('PropertiesFileExtension', 'yaml').lower();
PropertiesFileName: str = f'{PN}.{PropertiesFileExtension}';
SourceFileName: str = f'{SN}.{(Settings.get("SourceFileExtension", "luau")).lower()}';
UseYAML: bool = ('y' in PropertiesFileExtension);

RootFolderName: str = Settings.get('RootFolderName', Settings.get('RecycleBinParent', 'Silicon'));
PluginFolderName: str = Settings.get('PluginFolderName', 'Plugin');
RecycleBinFolderName: str = Settings.get('RecycleBinFolderName', Settings.get('RecycleBinName', 'Recycle Bin'));



def Import(Data: Dict[str, Any], Path: str = BasePath, IsLIVE: bool = False) -> (None):
    if not IsLIVE and Settings.get('CleanUpBeforeImportInIDE', False):
        if os.path.isdir(BasePath):
            for ImportedServiceFolder in os.listdir(BasePath):
                DeletePath(os.path.join(BasePath, ImportedServiceFolder));

    for Key, Value in Data.items():
        NewPath: str = os.path.join(Path, Key);

        if (Key == SN):
            try:
                with open(os.path.join(Path, SourceFileName), 'w', encoding = 'utf-8') as File:
                    File.write(Value);

            except Exception as Error:
                LogException(Error, f'write Source File for {Path}!');

        elif (Key == PN):
            try:
                PropsFilePath, _, IsActualYAML = ResolvePropertiesFileTarget(Path);
                with open(PropsFilePath, 'w', encoding = 'utf-8') as File:
                    if IsActualYAML:
                        yaml.dump(Value, File, default_flow_style = False, allow_unicode = True, sort_keys = False);

                    else:
                        json.dump(Value, File, indent = 2);

            except Exception as Error:
                LogException(Error, f'write Properties File for {Path}!');

        else:
            os.makedirs(NewPath, exist_ok = True);
            Import(Value, NewPath, IsLIVE);



def Export(ScriptToSynchronize: Optional[str] = None) -> (Dict[str, Any]):
    Hierarchy: Dict[str, Any] = { };
    ObjectsList: List[Dict[str, Any]] = [ ];
    SynchronizeAllDescendants: bool = Settings.get('SynchronizeAllDescendants', Settings.get('SyncAllDescendants', False));

    AllDirs: List[str] = [ ];
    ScriptAncestors: Set[str] = set();

    for RootPath, Dirs, Files in os.walk(BasePath):
        Dirs[:] = [Directory for Directory in Dirs if (Directory not in IgnoredDirectories) and (not IsPathIgnored(os.path.relpath(os.path.join(RootPath, Directory), BasePath)))];
        RelDir: str = os.path.relpath(RootPath, BasePath).replace('\\', '/');

        if (RelDir == '.') or IsPathIgnored(RelDir):
            continue;

        AllDirs.append(RootPath);

        HasScriptSource: bool = any(
            (FileName.startswith('Source.') or FileName.startswith('__Source__.') or FileName.endswith('.luau') or FileName.endswith('.lua'))
            and (FileName != PropertiesFileName) and (FileName != 'Properties.json') and (FileName != 'Properties.yaml')
            for FileName in Files
        );

        RecycleBinRelativePath: str = f'ReplicatedStorage/{RootFolderName}/{RecycleBinFolderName}';
        IsInRecycleBin: bool = (
            (RelDir in ('ReplicatedStorage', f'ReplicatedStorage/{RootFolderName}', RecycleBinRelativePath, 'ReplicatedStorage/Silicon', 'ReplicatedStorage/Silicon/Recycle Bin'))
            or RelDir.startswith(f'{RecycleBinRelativePath}/')
            or RelDir.startswith('ReplicatedStorage/Silicon/Recycle Bin/')
        );

        if HasScriptSource or IsInRecycleBin:
            Segments: List[str] = RelDir.split('/');

            for Length in range(1, (len(Segments) + 1)):
                ScriptAncestors.add('/'.join(Segments[:Length]));

    AllDirs.sort(key = lambda P: len(P.split(os.sep)));

    for ObjectDir in AllDirs:
        RelPath: str = os.path.relpath(ObjectDir, BasePath).replace('\\', '/');

        if not SynchronizeAllDescendants and (RelPath not in ScriptAncestors):
            SendToRecycleBin(ObjectDir);
            continue;

        PropsFilePath: str = ResolvePropertiesFileTarget(ObjectDir)[0];

        ClassName: str = 'Folder';
        Properties: Dict[str, Any] = { };
        Attributes: Dict[str, Any] = { };
        Tags: List[str] = [ ];

        if os.path.isfile(PropsFilePath):
            try:
                with open(PropsFilePath, 'r', encoding = 'utf-8', errors = 'replace') as PropsFile:
                    LoadedData: Dict[str, Any] = yaml.safe_load(PropsFile) or { };
                    ClassName = LoadedData.get('ClassName', 'Folder');
                    Properties = LoadedData.get('Properties', { });
                    Attributes = LoadedData.get('Attributes', { });
                    Tags = LoadedData.get('Tags', [ ]);

            except Exception as ReadError:
                print(f'[Silicon Server] Warning: could not parse {PropsFilePath}: {ReadError}');

        ScriptSource: Optional[str] = None;
        ScriptType: Optional[str] = None;

        for FileName in os.listdir(ObjectDir):
            FilePath: str = os.path.join(ObjectDir, FileName);

            if os.path.isfile(FilePath) and (FileName.startswith('Source.') or FileName.startswith('__Source__.') or FileName.endswith('.luau') or FileName.endswith('.lua')):
                if (FileName == PropertiesFileName) or (FileName == 'Properties.json') or (FileName == 'Properties.yaml'):
                    continue;

                try:
                    with open(FilePath, 'r', encoding = 'utf-8', errors = 'replace') as SourceHandle:
                        ScriptSource = SourceHandle.read();
                        ScriptType = InferScriptTypeFromFileName(FileName);

                        break;

                except OSError:
                    pass;

        ObjectsList.append({
            'path'      : RelPath,
            'className' : ClassName,
            'properties': Properties,
            'attributes': Attributes,
            'tags'      : Tags,
            'source'    : ScriptSource,
            'scriptType': ScriptType,
        });

    Hierarchy['files'] = ObjectsList;

    return Hierarchy;



if (__name__ == '__main__'):
    Parser: ArgumentParser = argparse.ArgumentParser(description = 'Silicon IDE Daemon for RS synchronization');

    for ArgumentName, ArgumentShort, ArgumentType, ArgumentDescription in DaemonArguments:
        Parser.add_argument(ArgumentName, ArgumentShort, type = ArgumentType, help = ArgumentDescription);

    Parser.add_argument('--AllDescendants', '-a', action = 'store_true', default = False, help = 'Synchronize all descendants of game, not only direct ancestry of scripts');
    Parser.add_argument('--Stop', '-x', action = 'store_true', default = False, help = 'Stop the currently running Silicon server');
    Parser.add_argument('--Clear', '-c', action = 'store_true', default = False, help = 'Clear all synchronized project files in Silicon/Game by moving them to the Recycle Bin');

    Arguments: Namespace = Parser.parse_args();

    SynchronizeAllDescendantsFlag: bool = getattr(Arguments, 'AllDescendants', False);
    StopServerFlag: bool = getattr(Arguments, 'Stop', False);
    ClearProjectFlag: bool = getattr(Arguments, 'Clear', False);

    if Arguments.Settings:
        Settings = LoadSettings(Arguments.Settings);
        PN = Settings.get('PropertiesName', 'Properties');
        SN = Settings.get('SourceName', 'Source');
        PropertiesFileExtension = Settings.get('PropertiesFileExtension', 'yaml').lower();
        PropertiesFileName = f'{PN}.{PropertiesFileExtension}';
        SourceFileName = f'{SN}.{(Settings.get("SourceFileExtension", "luau")).lower()}';
        UseYAML = ('y' in PropertiesFileExtension);
        RootFolderName = Settings.get('RootFolderName', Settings.get('RecycleBinParent', 'Silicon'));
        PluginFolderName = Settings.get('PluginFolderName', 'Plugin');
        RecycleBinFolderName = Settings.get('RecycleBinFolderName', Settings.get('RecycleBinName', 'Recycle Bin'));

    if SynchronizeAllDescendantsFlag:
        Settings['SynchronizeAllDescendants'] = True;
        Settings['SyncAllDescendants'] = True;

    BasePath = ResolveGameBasePath(Arguments.Target);

    Host: str = (Arguments.Host) or Settings.get('ServerHost', 'localhost');
    Port: int = (Arguments.Port) or Settings.get('ServerPort', 6969);

    ServerURL: str = f'http://{Host}:{Port}';
    ServerType: str = (getattr(Arguments, 'Requests', None) or Settings.get('ServerType', 'POST GET')).lower();

    Script: Optional[str] = (Arguments.Script) or Settings.get('ScriptToSynchronize') or Settings.get('Script');

    if ClearProjectFlag:
        ClearedViaServer: bool = False;

        try:
            ClearResponse: requests.Response = requests.post(
                f'{ServerURL}/clear',
                json    = { 'origin': 'IDE' },
                timeout = 2.0,
            );
            ClearedViaServer = ((ClearResponse.status_code) == 200);

        except Exception:
            pass;

        if ClearedViaServer:
            print(f'[Silicon Server] Cleared project directory via running server at {ServerURL}!');

        else:
            ClearProjectDirectory(BasePath, NotifyRS = False);

        sys.exit(0);

    if StopServerFlag:
        StoppedCleanly: bool = False;

        try:
            StopResponse: requests.Response = requests.post(f'{ServerURL}/stop', timeout = 2.0);
            StoppedCleanly = ((StopResponse.status_code) == 200);

        except Exception:
            pass;

        if StoppedCleanly:
            print(f'[Silicon Server] Successfully stopped the Silicon server at {ServerURL}!');

        else:
            print(f'[Silicon Server] No active Silicon server found at {ServerURL}.');

        sys.exit(0);

    if not IsHTTPServerRunning(ServerURL):
        os.makedirs(BasePath, exist_ok = True);
        StartWatcher();

        ThreadingHTTPServer.allow_reuse_address = True;
        Server = ThreadingHTTPServer(
            (Host, Port),
            GetHandler(('p' in ServerType), ('g' in ServerType), False)
        );
        Server.daemon_threads = True;
        ServerThread = threading.Thread(
            target = lambda: Server.serve_forever(),
        );
        ServerThread.start();

        Version: str = Settings.get('Version', '0.0.0');
        print(f'[Silicon Server] Silicon IDE Daemon v{Version} started!');
        print(f'[Silicon Server] Successfully started server! - Listening on {ServerURL}');
        print('[Silicon Server] Waiting for RS connection...');
        print('[Silicon Server] Mode and commands are driven from RS.');
        print('[STANDBY LISTENER: READY FOR RS COMMANDS]');
        print('IDE <-> RS');

        try:
            while WatcherRunning and ServerThread and ServerThread.is_alive():
                time.sleep(1.0);

        except KeyboardInterrupt:
            StopHTTPServer();

    else:
        Version: str = Settings.get('Version', '0.0.0');
        print(f'[Silicon Server] Silicon IDE Daemon v{Version} is already running on {ServerURL}!');
        print('[STANDBY LISTENER: READY FOR RS COMMANDS]');
        print('IDE <-> RS');

