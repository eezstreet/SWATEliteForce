class Do_DisableTargetBombs extends Do_DisableTargetInanimates;

function OnTimeExpired()
{
    Super.OnTimeExpired();

    Game.BombExploded();
}
