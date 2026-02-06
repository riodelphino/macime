public enum Help {
   public static let macime = """
   Usage: macime <sub_command> [<options>]

   Sub commands:
      get     Get current IME
      set     Set IME
      save    Save IME
      load    Restore IME
      list    List IMEs

   Get current IME
      macime get [--detail] [--launchd]

   Set IME 
      macime set <IME_id> [--save] [--session-id <session_id>] [--launchd]

      Set IME only (no save)
         macime set <IME_id>
      
      Set IME while saving current IME to `DEFAULT` file in temp dir
         macime set <IME_id> --save
      
      Set IME while saving current IME to `<session_id>` file in temp dir
         macime set <IME_id> --save --session-id <session_id>

   Save IME
      macime save [--session-id <session_id>] [--launchd]

      Save current IME to `DEFAULT` file in temp dir
         macime save

      Save current IME to `<session_id>` file in temp dir
         macime save --session-id <session_id>

   Load (restore) IME
      macime load [--session-id <session_id>] [--launchd]

      Load previouse IME from `DEFAULT` file in temp dir
         macime load

      Load previous IME from `<session_id>` file in temp dir
         macime load --session-id <session_id>

   List IMEs
      macime list [--detail] [--select-capable] [--launchd]


   OPTIONS:
      --help, -h
         Show help

      --version, -v
         Show version

      --detail
         Show detailed IME info as JSON
         
      --select-capable
         Show only selectable IME

      --save
         Save current IME

      --session-id <session_id>
         Specify the save filename

      --cjk-refresh 
         Refresh IME for CJK input methods

      --launchd
         Indicate the command is called via launchd
   """
   public static let macimed = """
   Usage: macimed [options]

   A daemon tool that wraps `macime` command for launchd service.

   To start service via Homebrew (Faster):
      brew services start macime 

   To start service manually for debugging (Slower):
      macimed

   OPTIONS:

      --help, -h
         Show help

      --version, -v
         Show version
   """
}
