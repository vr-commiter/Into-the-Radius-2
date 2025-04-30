using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection.Emit;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Win32;
using MyTrueGear;

namespace IntoTheRadius2_TrueGear
{
    public partial class Form1: Form
    {
        private static string steamAppID = "2307350";
        private static string inertFilePath = "\\IntoTheRadius2\\Binaries\\Win64\\TrueGear.log";
        private static string listenFilePath = null;

        private static bool first = true;
        private static int counter = 0;

        private static TrueGearMod _TrueGear = null;
        private static Thread runLogThread = null;

        private static string _SteamExe;
        public const string STEAM_OPENURL = "steam://rungameid/2307350";

        private static long lastPoisonDamageTime = 0;
        private static long lastFireDamageTime = 0;
        private static long lastIncapacitatedDamageTime = 0;

        private static string _selectedPath = null;
        private static bool threadOnce = true;
        private static string appName = "IntoTheRadius2.exe";

        public class LanguageItem
        {
            public string Name { get; set; } // 显示的名称，如“中文”
            public string Code { get; set; } // 实际的值，如“zh-CN”
        }

        /// <summary>
        /// 指定窗体载入语言
        /// </summary>
        /// <param name="aForm"></param>
        /// <param name="aFormType"></param>
        public static void LoadLanguage(Form aForm, string language)
        {
            if (aForm != null)
            {
                Thread.CurrentThread.CurrentUICulture = new CultureInfo(language);

                ComponentResourceManager resources = new ComponentResourceManager(aForm.GetType());
                resources.ApplyResources(aForm, "$this");
                LoadingControls(aForm, resources);
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="aControl"></param>
        /// <param name="aResources"></param>
        private static void LoadingControls(Control aControl, ComponentResourceManager aResources)
        {
            if (aControl is MenuStrip)
            {
                //将资源与控件对应
                aResources.ApplyResources(aControl, aControl.Name);
                MenuStrip menu = (MenuStrip)aControl;
                if (menu.Items.Count > 0)
                {
                    foreach (ToolStripMenuItem item in menu.Items)
                    {
                        //遍历菜单
                        Loading(item, aResources);
                    }
                }
            }

            foreach (Control ctrl in aControl.Controls)
            {
                aResources.ApplyResources(ctrl, ctrl.Name);
                LoadingControls(ctrl, aResources);
            }
        }

        /// <summary>
        /// 遍历菜单
        /// </summary>
        /// <param name="aItem">菜单项</param>
        /// <param name="aResources">语言资源</param>
        private static void Loading(ToolStripMenuItem aItem, ComponentResourceManager aResources)
        {
            if (aItem is ToolStripMenuItem)
            {
                aResources.ApplyResources(aItem, aItem.Name);
                if (aItem.DropDownItems.Count > 0)
                {
                    foreach (ToolStripMenuItem item in aItem.DropDownItems)
                    {
                        Loading(item, aResources);
                    }
                }
            }
        }

        public static string SteamExePath()
        {
            return (string)Registry.GetValue(@"HKEY_CURRENT_USER\SOFTWARE\Valve\Steam", "SteamExe", null);
        }

        public static string FindSteamAppIDPatch(string appID)
        {
            string steamPath = GetSteamPath();
            if (steamPath != null)
            {
                string gamePath = GetGamePath(steamPath, appID);
                return gamePath;
            }
            else
            {
                Console.WriteLine("未找到游戏路径");
            }
            return null;
        }

        public static string GetGamePath(string steamPath, string appId)
        {
            string libraryFoldersPath = System.IO.Path.Combine(steamPath, "steamapps", "libraryfolders.vdf");
            List<string> libraryFolders = ParseVdf(libraryFoldersPath);

            string gamePath = FindGamePath(libraryFolders, appId);

            if (gamePath != null)
            {
                gamePath = gamePath.Replace("/", @"\");
                gamePath = gamePath.Replace(@"\\", @"\");
                return gamePath;
            }
            else
            {
                Console.WriteLine("未找到游戏路径");
            }

            return null;
        }

        public static List<string> ParseVdf(string filePath)
        {
            var libraryFolders = new List<string>();
            string fileContent = File.ReadAllText(filePath);

            var matches = Regex.Matches(fileContent, "\"path\"\\s*\"(.+?)\"");

            foreach (Match match in matches)
            {
                libraryFolders.Add(match.Groups[1].Value);
            }
            return libraryFolders;
        }

        public static string FindGamePath(List<string> libraryFolders, string appId)
        {
            foreach (var folder in libraryFolders)
            {
                string manifestPath = System.IO.Path.Combine(folder, $"steamapps/appmanifest_{appId}.acf");
                if (File.Exists(manifestPath))
                {
                    string installDir = ParseInstallDir(manifestPath);
                    if (!string.IsNullOrEmpty(installDir))
                    {
                        return System.IO.Path.Combine(folder, "steamapps/common/", installDir);
                    }
                }
            }

            return null;
        }

        public static string ParseInstallDir(string manifestPath)
        {
            string fileContent = File.ReadAllText(manifestPath);
            var match = Regex.Match(fileContent, "\"installdir\"\\s*\"(.+?)\"");

            if (match.Success)
            {
                return match.Groups[1].Value;
            }

            return null;
        }

        public static string GetSteamPath()
        {
            using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\WOW6432Node\Valve\Steam"))
            {
                if (key != null)
                {
                    return key.GetValue("InstallPath") as string;
                }
            }
            return null;
        }

        public Form1()
        {
            string currentProcessName = Process.GetCurrentProcess().ProcessName;
            Process[] processes = Process.GetProcessesByName(currentProcessName);
            if (processes.Length > 1)
            {
                if (processes[0].UserProcessorTime.TotalMilliseconds > processes[1].UserProcessorTime.TotalMilliseconds)
                {
                    processes[0].Kill();
                }
                else
                {
                    processes[1].Kill();
                }
            }

            InitializeComponent();

            List<LanguageItem> languages = new List<LanguageItem>
            {
                new LanguageItem { Name = "中文", Code = "zh-CN" },
                new LanguageItem { Name = "English", Code = "en-US" }
                
                // 可以继续添加其他语言
            };

            int lastLanguage = Properties.Settings.Default.LastLanguage;
            Language.DataSource = languages;
            Language.DisplayMember = "Name"; // ComboBox显示的列
            Language.ValueMember = "Code"; // ComboBox实际存储的值
            Language.SelectedIndex = lastLanguage;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            string lastUsedPath = Properties.Settings.Default.LastUsedPath;
            if (!string.IsNullOrEmpty(lastUsedPath))
            {
                if (CheckPath(lastUsedPath))
                {
                    listenFilePath = lastUsedPath + inertFilePath;

                    _TrueGear = new TrueGearMod();

                    runLogThread = new Thread(runGetLog);
                    runLogThread.Start();

                    if (CheckPath(FindSteamAppIDPatch(steamAppID)))
                    {
                        Thread.Sleep(500);
                        _SteamExe = SteamExePath();
                        if (_SteamExe != null) Process.Start(_SteamExe, STEAM_OPENURL);
                    }
                    else
                    {
                        try
                        {
                            var processInfo = new ProcessStartInfo
                            {
                                FileName = System.IO.Path.Combine(_selectedPath, appName),
                                UseShellExecute = true
                            };
                            Process.Start(processInfo);
                        }
                        catch
                        {
                            if (Language.SelectedIndex == 0)
                            {
                                MessageBox.Show("开启游戏失败", "请手动开启");
                            }
                            else
                            {
                                MessageBox.Show("Failed to start the game", "Please start the game manually.");
                            }
                        }
                    }
                    Play.Enabled = false;
                    Select.Enabled = false;
                }
                else
                {
                    if (Language.SelectedIndex == 0)
                    {
                        Path.Text = "请选择路径游戏的根目录";
                    }
                    else
                    {
                        Path.Text = "Please select the path to the root directory of the game.";
                    }
                    Play.Enabled = false;
                    Stop.Enabled = false;
                }
            }
            else
            {
               string appIDPath = FindSteamAppIDPatch(steamAppID);
                if (!CheckPath(appIDPath))
                {
                    if (Language.SelectedIndex == 0)
                    {
                        Path.Text = "请选择路径游戏的根目录";
                    }
                    else
                    {
                        Path.Text = "Please select the path to the root directory of the game.";
                    }                    
                    Play.Enabled = false;
                    Stop.Enabled = false;
                }
            }
        }

        public static void runGetLog()
        {
            try
            {
                while (true)
                {
                    if (File.Exists(listenFilePath))
                    {
                        if (first)
                        {
                            first = false;
                            File.WriteAllText(listenFilePath, "");
                            counter = ReadLines(listenFilePath).Count();
                        }

                        int lineCount = ReadLines(listenFilePath).Count();
                        if (counter < lineCount && lineCount > 0)
                        {
                            var lines = Enumerable.ToList(ReadLines(listenFilePath).Skip(counter).Take(lineCount - counter));
                            for (int i = 0; i < lines.Count; i++)
                            {
                                if (lines[i].Contains("[TrueGear]"))
                                {
                                    string line = lines[i].Substring(lines[i].LastIndexOf(':') + 1);
                                    string trimmedInput = line.Trim('{', '}');

                                    //Console.WriteLine("---------------------------------------");
                                    //Console.WriteLine(trimmedInput);
                                    GameEventCheck(trimmedInput);
                                    //_TrueGear.Play(trimmedInput);
                                }
                            }
                            counter += lines.Count;
                        }
                        else if (counter == lineCount && lineCount > 0)
                        {
                            Thread.Sleep(50);
                        }
                        else
                        {
                            counter = 0;
                        }
                    }
                    else
                    {
                        Console.WriteLine("未找到log文件 ：" + listenFilePath);
                        Thread.Sleep(10000);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("发生异常：" + ex.Message);
                Console.WriteLine("堆栈跟踪：" + ex.StackTrace);
            }
        }

        public static IEnumerable<string> ReadLines(string path)
        {
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 0x1000, FileOptions.SequentialScan))
            using (var sr = new StreamReader(fs, Encoding.UTF8))
            {
                string line;
                while ((line = sr.ReadLine()) != null)
                {
                    yield return line;
                }
            }
        }

        private void Play_Click(object sender, EventArgs e)
        {
            if (threadOnce)
            {
                threadOnce = false;
                runLogThread = new Thread(runGetLog);
                runLogThread.Start();
                Play.Enabled = false;
                Stop.Enabled = true;
                Select.Enabled = false;
                _TrueGear = new TrueGearMod();
            }
            else
            {
                if (Language.SelectedIndex == 0)
                {
                    MessageBox.Show("无需再次点击", "你已开始");
                }
                else
                {
                    MessageBox.Show("No more clicks", "You've already played");
                }
            }
            if (CheckPath(FindSteamAppIDPatch(steamAppID)))
            {
                Thread.Sleep(500);
                if (_SteamExe != null) Process.Start(_SteamExe, STEAM_OPENURL);
            }
            else
            {
                try
                {
                    var processInfo = new ProcessStartInfo
                    {
                        FileName = System.IO.Path.Combine(_selectedPath, appName),
                        UseShellExecute = true
                    };
                    Process.Start(processInfo);
                }
                catch
                {
                    if (Language.SelectedIndex == 0)
                    {
                        MessageBox.Show("开启游戏失败", "请手动开启");
                    }
                    else
                    {
                        MessageBox.Show("Failed to start the game", "Please start the game manually.");
                    }
                }
            }
        }

        private void Stop_Click(object sender, EventArgs e)
        {
            string que;
            string confirm;
            que = "Confirm stop?";
            confirm = "Confirm"; 
            DialogResult result = MessageBox.Show(que, confirm, MessageBoxButtons.YesNo);
            if (result == DialogResult.Yes)
            {
                runLogThread.Abort();
                first = true;
                counter = 0;
                threadOnce = true;
                Play.Enabled = true;
                Stop.Enabled = false;
                Select.Enabled = true;
                _TrueGear = null;
                if (Language.SelectedIndex == 0)
                {
                    MessageBox.Show("你已停止", "");
                }
                else
                {
                    MessageBox.Show("You've stopped", "");
                }
            }
        }

        private void Select_Click(object sender, EventArgs e)
        {
            if (folderBrowserDialog1.ShowDialog() == DialogResult.OK)
            {
                string tmpSelectedPath = folderBrowserDialog1.SelectedPath;
                if (!CheckPath(tmpSelectedPath))
                {
                    _selectedPath = null;
                    if (Language.SelectedIndex == 0)
                    {
                        Path.Text = "请选择路径游戏的根目录";
                    }
                    else
                    {
                        Path.Text = "Please select the path to the root directory of the game.";
                    }

                    Properties.Settings.Default.LastUsedPath = _selectedPath;
                    Properties.Settings.Default.Save();
                    Play.Enabled = false;
                    Stop.Enabled = false;
                }
            }
        }

        private void Language_SelectedIndexChanged(object sender, EventArgs e)
        {
            Properties.Settings.Default.LastLanguage = Language.SelectedIndex;
            Properties.Settings.Default.Save();
            Console.WriteLine(Language.SelectedIndex);
            string selectedLanguage = Language.SelectedValue.ToString();

            // 根据语言代码设置CultureInfo
            CultureInfo culture = new CultureInfo(selectedLanguage);
            Thread.CurrentThread.CurrentCulture = culture;
            Thread.CurrentThread.CurrentUICulture = culture;

            // 加载语言资源并应用到UI
            LoadLanguage(this, selectedLanguage);
            string lastUsedPath = Properties.Settings.Default.LastUsedPath;
            if (CheckPath(lastUsedPath))
            {
                Path.Text = lastUsedPath;
            }
            else
            {
                if (Language.SelectedIndex == 0)
                {
                    Path.Text = "请选择路径游戏的根目录";
                }
                else
                {
                    Path.Text = "Please select the path to the root directory of the game.";
                }
            }
        }

        private bool CheckPath(string tmpSelectedPath)
        {
            try
            {
                string tmpFilePath = System.IO.Path.Combine(tmpSelectedPath, appName);
                if (File.Exists(tmpFilePath))
                {
                    _selectedPath = tmpSelectedPath;
                    Path.Text = _selectedPath;
                    Properties.Settings.Default.LastUsedPath = _selectedPath;
                    Properties.Settings.Default.Save();
                    Play.Enabled = true;
                    return true;
                }
                return false;
            }
            catch
            {
                return false;
            }
        }

        private static void GameEventCheck(string gameEvent)
        {
            string[] damage = gameEvent.Split(',');

            if (damage.Length != 1)
            {
                _TrueGear.PlayAngle(damage[0], float.Parse(damage[1]), float.Parse(damage[2]));
                Console.WriteLine($"Play :{damage[0]},{damage[1]},{damage[2]}");
            }
            else
            {
                _TrueGear.Play(damage[0]);
                Console.WriteLine($"Play :{damage[0]}");
            }
        }


    }
}
