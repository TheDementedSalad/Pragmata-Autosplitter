//Pragmata Autosplitter V1.0.0 (17 April 2026)
//Supports LRT and Game Splits
//Script & Pointers by TheDementedSalad
//Cutscene/Event pointers by Rumii

state("PRAGMATA"){
}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
	vars.Helper.Settings.CreateFromXml("Components/Pragmata.Settings.xml");
	
	// Asks user to change to game time if LiveSplit is currently set to Real Time.
		if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {        
        var timingMessage = MessageBox.Show (
            "This game uses In Game Time as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | PRAGMATA",
            MessageBoxButtons.YesNo,MessageBoxIcon.Question
        );

        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

init
{

	IntPtr GameClock = vars.Uhara.ScanRel(3, "48 8b 3d ?? ?? ?? ?? 48 83 78");
	IntPtr ConversationManager = vars.Uhara.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 85 d2 74 ?? 44 8a 40");
	IntPtr FadeManager = vars.Uhara.ScanRel(3, "48 8b 3d ?? ?? ?? ?? 48 8b 0d ?? ?? ?? ?? c5");
	IntPtr AppEventManager = vars.Uhara.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 85 d2 0f 84 ?? ?? ?? ?? 4e 8b 74 fb");
	IntPtr ObjectiveManager = vars.Uhara.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 89 f1 48 85 d2 74 ?? e8 ?? ?? ?? ?? 34");
	IntPtr SkipEventManager = vars.Uhara.ScanRel(3, "48 8b 05 ?? ?? ?? ?? 48 85 c0 74 ?? 8b 48 ?? 48 83 c0");
	IntPtr MiniDemoManager = vars.Uhara.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 8b 83");
	
	vars.Helper["GameElapsedTime"] = vars.Helper.Make<long>(GameClock, 0x18);
	vars.Helper["DemoSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x20);
	vars.Helper["PauseSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x28);
	vars.Helper["MeasureGameSpendingTime"] = vars.Helper.Make<byte>(GameClock, 0x8C);
	vars.Helper["MeasureDemoSpendingTimeBits"] = vars.Helper.Make<byte>(GameClock, 0x88);
	vars.Helper["MeasurePauseSpendingTimeBits"] = vars.Helper.Make<byte>(GameClock, 0x80);
	
	vars.Helper["PlayingEvent"] = vars.Helper.Make<bool>(ConversationManager, 0x259);
	vars.Helper["PlayingTalkID"] = vars.Helper.Make<uint>(ConversationManager, 0x244);
	
	vars.Helper["MenuFade"] = vars.Helper.Make<byte>(FadeManager, 0x10, 0x28, 0x90);
	vars.Helper["EventFade"] = vars.Helper.Make<byte>(FadeManager, 0x10, 0x38, 0x90);
	
	vars.Helper["MovieID"] = vars.Helper.MakeString(AppEventManager, 0x30, 0x20, 0x10, 0x20, 0x20, 0x38, 0x10, 0x28, 0x14);
	vars.Helper["MovieID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["MovieStatus"] = vars.Helper.Make<bool>(AppEventManager, 0x30, 0x20, 0x10, 0x20, 0x4A);
	vars.Helper["MovieStatus"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["DemoID"] = vars.Helper.MakeString(AppEventManager, 0x30, 0x28, 0x10, 0x20, 0x20, 0x38, 0x10, 0x28, 0x14);
	vars.Helper["DemoID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["DemoStatus"] = vars.Helper.Make<bool>(AppEventManager, 0x30, 0x28, 0x10, 0x20, 0x28, 0xA4);
	vars.Helper["DemoStatus"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.Helper["ObjectiveSize"] = vars.Helper.Make<int>(ObjectiveManager, 0x30, 0x18);
	
	//vars.Helper["MiniDemoID"] = vars.Helper.MakeString(SkipEventManager, 0x30, 0x10, 0x20, 0x10, 0x28, 0x14);
	//vars.Helper["MiniDemoID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["MiniDemoPhase"] = vars.Helper.Make<byte>(SkipEventManager, 0x30, 0x10, 0x20, 0x10, 0x20, 0x60, 0x18, 0x30, 0xF8);
	vars.Helper["MiniDemoPhase"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["TramPhase"] = vars.Helper.Make<bool>(SkipEventManager, 0x30, 0x10, 0x20, 0x94);
	vars.Helper["TramPhase"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["ISkipEventSetup"] = vars.Helper.Make<bool>(SkipEventManager, 0x134);
	vars.Helper["ISkipEventSetup"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["SkippableEventCount"] = vars.Helper.Make<byte>(SkipEventManager, 0x38);
	
	vars.Helper["MiniDemoID"] = vars.Helper.MakeString(MiniDemoManager, 0x10, 0x10, 0x20, 0x10, 0x28, 0x14);
	vars.Helper["MiniDemoID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["MiniDemoSize"] = vars.Helper.Make<byte>(MiniDemoManager, 0x10, 0x10, -8);
	
	vars.QuestList = new List<uint>();
	vars.MiniDemos = new List<string>();
	vars.completedSplits = new HashSet<string>();
	vars.Objective = new Dictionary<uint, byte>();
	
	vars.ObjectiveManager = ObjectiveManager;
	vars.MiniDemoManager = MiniDemoManager;
	
	vars.PendingSplits = 0;
}

onStart
{
	vars.QuestList.Clear();
	vars.MiniDemos.Clear();
	vars.completedSplits.Clear();
	vars.Objective.Clear();
	vars.PendingSplits = 0;
}

start
{
}


update
{
	//print(modules.First().ModuleMemorySize.ToString());
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	current.Quests = new uint[current.ObjectiveSize];
	current.MiniDemos = new string[current.MiniDemoSize];
	
	for (int i = 0; i < current.ObjectiveSize; i++)
		current.Quests[i] = vars.Helper.Read<uint>(vars.ObjectiveManager, 0x30, 0x10, 0x20 + (i * 0x8), 0x10);
	
	for (int i = 0; i < current.MiniDemoSize; i++)
		current.MiniDemos[i] = vars.Helper.ReadString(300, ReadStringType.UTF16, vars.MiniDemoManager, 0x10, 0x10, 0x20 + (i * 0x8), 0x10, 0x28, 0x14);
	
	
	if(!string.IsNullOrEmpty(current.DemoID)){
        current.Demo = current.DemoID.Substring(2,4);
    }
	
	if(!string.IsNullOrEmpty(current.MovieID)){
        current.Movie = current.MovieID.Substring(2,4);
    }
}

gameTime
{
}

split
{
	string MStartSetting = "";
	string MCompSetting = "";
	string DemoSetting = "";
	string MiniDemoSetting = "";
	string MovieSetting = "";
	string ConvoSetting = "";
	
	for (int i = 0; i < current.ObjectiveSize; i++){
		uint mission = vars.Helper.Read<uint>(vars.ObjectiveManager, 0x30, 0x10, 0x20 + (i * 0x8), 0x10);
		byte chapter = vars.Helper.Read<byte>(vars.ObjectiveManager, 0x30, 0x10, 0x20 + (i * 0x8), 0x20);
		byte complete = vars.Helper.Read<byte>(vars.ObjectiveManager, 0x30, 0x10, 0x20 + (i * 0x8), 0x24);

		byte oldComplete;
		if (vars.Objective.TryGetValue(mission, out oldComplete))
		{
			
			if (complete == 2 && oldComplete != 2){
				MCompSetting = mission + "_" + chapter + "_" + complete;
			}
				
			if(!vars.completedSplits.Contains(MCompSetting)){
					if (settings.ContainsKey(MCompSetting) && settings[MCompSetting]){
					vars.PendingSplits++;
				}
			}
				
			if (!string.IsNullOrEmpty(MCompSetting))
			vars.Log(MCompSetting);
		}
		
		vars.Objective[mission] = complete;
	}
	
	if(current.ObjectiveSize != old.ObjectiveSize){
		for (int i = 0; i < current.ObjectiveSize; i++) {
			
			uint mission = vars.Helper.Read<uint>(vars.ObjectiveManager, 0x30, 0x10, 0x20 + (i * 0x8), 0x10);
			var missions = current.Quests[i];
		  
				if(missions != 0 && !vars.QuestList.Contains(mission)){
				MStartSetting = missions + "_New";
				vars.QuestList.Add(mission);
			}
			
			if(!vars.completedSplits.Contains(MStartSetting)){
					if (settings.ContainsKey(MStartSetting) && settings[MStartSetting]){
					vars.PendingSplits++;
				}
			}
			
			if (!string.IsNullOrEmpty(MStartSetting))
			vars.Log(MStartSetting);
		}
	}
	
	if(!string.IsNullOrEmpty(current.DemoID) && current.DemoStatus && !old.DemoStatus){
		DemoSetting = "cs_" + current.Demo;
			
		if (!string.IsNullOrEmpty(DemoSetting))
		vars.Log(DemoSetting);
	
		if(!vars.completedSplits.Contains(DemoSetting)){
				if (settings.ContainsKey(DemoSetting) && settings[DemoSetting]){
				vars.PendingSplits++;
			}
		}
	}
	
	if(!string.IsNullOrEmpty(current.MovieID) && current.MovieStatus && !old.MovieStatus){
		MovieSetting = "ev_" + current.Movie;
			
		if (!string.IsNullOrEmpty(MovieSetting))
		vars.Log(MovieSetting);
	
		if(!vars.completedSplits.Contains(MovieSetting)){
				if (settings.ContainsKey(MovieSetting) && settings[MovieSetting]){
				vars.PendingSplits++;
			}
		}
	}
	
	/*if((old.MiniDemoPhase == 0 || old.MiniDemoPhase == 1) && current.MiniDemoPhase == 2){
		ConvoSetting = "mini_" + current.MiniDemoID;
			
		if (!string.IsNullOrEmpty(ConvoSetting))
		vars.Log(ConvoSetting);
	
		if(!vars.completedSplits.Contains(ConvoSetting)){
				if (settings.ContainsKey(ConvoSetting) && settings[ConvoSetting]){
				vars.PendingSplits++;
			}
		}
	}
	*/
	
	if(current.MiniDemoSize != old.MiniDemoSize){
		for (int i = 0; i < current.MiniDemoSize; i++) {
			
			var minidemo = current.MiniDemos[i];

			if(!string.IsNullOrEmpty(minidemo)){
				MiniDemoSetting = minidemo.ToString();
			}
			
			if(!vars.completedSplits.Contains(MiniDemoSetting)){
					if (settings.ContainsKey(MiniDemoSetting) && settings[MiniDemoSetting]){
					vars.PendingSplits++;
				}
			}
			
			if (!string.IsNullOrEmpty(MiniDemoSetting))
			vars.Log(MiniDemoSetting);
		}
	}
	
	
	
	if (vars.PendingSplits > 0)
	{
		vars.PendingSplits--;
		vars.completedSplits.Add(MStartSetting);
		vars.completedSplits.Add(MCompSetting);
		vars.completedSplits.Add(DemoSetting);
		vars.completedSplits.Add(MovieSetting);
		vars.completedSplits.Add(ConvoSetting);
		vars.completedSplits.Add(MiniDemoSetting);
		return true;
	}
}


isLoading
{
	return current.MeasureDemoSpendingTimeBits != 0 || current.MeasurePauseSpendingTimeBits != 0 || current.EventFade == 1 || current.EventFade == 2 || 
		current.MenuFade == 1 || current.MenuFade == 2 || current.PlayingEvent || current.TramPhase;
}

reset
{
}

exit
{
}
