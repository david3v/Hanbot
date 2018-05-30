return {
    id = 'dCaitlyn',
    name = 'Caitlyn',
    flag = {
      text = "dCaitlyn",
      color = {
        text = 0xFF00BB4F,
        background1 = 0x66AAFFFF,
        background2 = 0x99000000,
      }
    },
    load = function()
      return player.charName == 'Caitlyn'
    end
}