class StatTrackerBase extends Core.Object
  abstract;

var private SwatGameInfo Game;

protected final function SwatGameInfo GetGame()
{
  assert(Game != None);
  return Game;
}

final function Init(SwatGameInfo GameInfo)
{
  Game = GameInfo;

  PostInitHook();
}

function PostInitHook();
