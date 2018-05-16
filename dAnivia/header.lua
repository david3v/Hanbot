return {
    id = 'dAnivia',
    name = 'Anivia',
    flag = {
      text = "dAnivia",
      color = {
        text = 0xFF00BB4F,
        background1 = 0x66AAFFFF,
        background2 = 0x99000000,
      }
    },
    load = function()
      return player.charName == 'Anivia'
    end
}