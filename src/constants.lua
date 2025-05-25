-- src/constants.lua
local constants = {}

constants.TARGET_SCORE = 15

constants.CARD_DEFS = {
    { id="wooden_cow", name="Wooden Cow", cost=1, power=1, text="Vanilla", triggers={} },
    { id="pegasus",    name="Pegasus",    cost=3, power=5, text="Vanilla", triggers={} },
    { id="minotaur",   name="Minotaur",   cost=5, power=9, text="Vanilla", triggers={} },
    { id="titan",      name="Titan",      cost=6, power=12,text="Vanilla", triggers={} },
    { id="zeus",       name="Zeus",       cost=7, power=4, text="When Revealed: Lower the power of each card in your opponent's hand by 1.", triggers={} },
    { id="hermes",     name="Hermes",     cost=3, power=1, text="When Revealed: Moves to another location.",          triggers={} },
    { id="hydra",      name="Hydra",      cost=6, power=3, text="Add two copies to your hand when this card is discarded.", triggers={} },
    { id="midas",      name="Midas",      cost=8, power=2, text="When Revealed: Set ALL cards here to 3 power.",    triggers={} },
    { id="aphrodite",  name="Aphrodite",  cost=6, power=3, text="When Revealed: Lower the power of each enemy card here by 1.", triggers={} },
    { id="athena",     name="Athena",     cost=6, power=2, text="Gain +1 power when you play another card here.",   triggers={} },
    { id="apollo",     name="Apollo",     cost=3, power=2, text="When Revealed: Gain +1 mana next turn.",           triggers={} },
    { id="nyx",        name="Nyx",        cost=7, power=4, text="When Revealed: Discards your other cards here, add their power to this card.", triggers={} },
    { id="daedalus",   name="Daedalus",   cost=5, power=3, text="When Revealed: Add a Wooden Cow to each other location.", triggers={} },
    { id="helios",     name="Helios",     cost=8, power=10,text="End of Turn: Discard this.",                        triggers={} },
}

return constants
