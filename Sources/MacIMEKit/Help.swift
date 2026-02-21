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
      macime get [--detail]

   Set IME 
      macime set <IME_id> [--save] [--session-id <session_id>]

      Set IME only (no save)
         macime set <IME_id>
      
      Set IME while saving current IME to 'GLOBAL' file in temp dir
         macime set <IME_id> --save
      
      Set IME while saving current IME to '<session_id>' file in temp dir
         macime set <IME_id> --save --session-id <session_id>

   Save IME
      macime save [--session-id <session_id>]

      Save current IME to 'GLOBAL' file in temp dir
         macime save

      Save current IME to '<session_id>' file in temp dir
         macime save --session-id <session_id>

   Load (restore) IME
      macime load [--session-id <session_id>]

      Load previouse IME from `GLOBAL` file in temp dir
         macime load

      Load previous IME from '<session_id>' file in temp dir
         macime load --session-id <session_id>

   List IMEs
      macime list [--detail] [--select-capable]


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
   """
   public static let macimed = """
   Usage: macimed [options]

   A daemon tool that wraps 'macime' command.

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
