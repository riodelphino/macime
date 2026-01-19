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
         macime get [--detail] [--json]

      Set IME 
         macime set <IME_id> [--save] [--session-id <session_id>]

         Set IME only (no save)
            macime set <IME_id>
         
         Set IME while saving current IME to `DEFAULT` file in temp dir
            macime set <IME_id> --save
         
         Set IME while saving current IME to `<session_id>` file in temp dir
            macime set <IME_id> --save --session-id <session_id>

      Save IME
         macime save [--session-id <session_id>]

         Save current IME to `DEFAULT` file in temp dir
            macime save

         Save current IME to `<session_id>` file in temp dir
            macime save --session-id <session_id>

      Load (restore) IME
         macime load [--session-id <session_id>]

         Load previouse IME from `DEFAULT` file in temp dir
            macime load

         Load previous IME from `<session_id>` file in temp dir
            macime load --session-id <session_id>

      List IMEs
         macime list [--detail] [--select-capable] [--json]


      OPTIONS:

         --detail
            Show detailed IME info
            
         --select-capable
            Show only selectable IME

         --json
            Output as json

         --save
            Save current IME

         --session-id <session_id>
            Specify the save filename

      """
   public static let macimed = """
      Usage: macimed

      This is a daemon tool that wraps `macime` command for launchd service.

      Start service with brew
        brew services start macime 

      Start service manually
         launchctl load ~/Library/LaunchAgents/com.riodelphino.macimed.plist
      """
}
