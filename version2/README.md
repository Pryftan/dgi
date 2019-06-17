# dgiv2

The second version of the engine has the same core functionality (and reads nearly the same JSON data), but is written to take advantage of proper Swift design. Textures for screens and sprites are drawn when needed instead of all at once, and many complex classes have been spread out or simplified.

Main classes:

DGIMenu - Defines the initial menu seen at launch.

DGIScreen - Basic configuration for most game scenes, including gestures and text boxes.

DGIVoid - Inherits from DGIScreen, implements the cutscenes between game rooms (the "void" where the player converses with the computer avatar).

DGIRoom - Inherits from DGIScreen, implements the game rooms. Much of this class is the initial setup from loading and parsing JSON, and flow logic for touches.

DGIAction - Extension of DGIRoom just to split out functionality for readability. Handling clickable regions and animations is done hre.
DGIRoomNode, DGIRoomSub - Extensions of SKSpriteNodes to add features for room contents. "sub" always refers to smaller images that are children of the main room backgrounds ("nodes").

DGITutorial - Implements the tutorial sequence that runs when new games are created, or when the tutorial is selected from the top menu.

DGIInventory, DGIInventoryObject - Handles the player inventory, extends from SKSpriteNode as well.

DGIJSON - Defines all JSON parsing objects including the Config singleton which houses global configuration options (like text size).

DGILineBox, DGISpeechBox, DGIChoiceBox - Logic for conversation boxes and dialogue options.

DGISave - Defines saving the game, and the Autosave singleton.

DGIExtensions - Various utility extensions to standard Swift classes.

AppDelegate, DGIViewController - Basic app launch modelled from standard Swift templates.

Notes for coming improvements and development can be found in Projects.
