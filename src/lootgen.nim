import docopt, tables, strutils, parseutils
import polydicepkg/dice
import streams, strutils

let doc = """
A tool for generating random 5e treasure.

Usage:
    lootgen individual [-n=<num>] (-c=<CR> | --cr=<CR>)
    lootgen coins [-n=<num>] <dice>
    lootgen (-h | --help)
    lootgen --version

Options:
    -c=<CR> --cr=<CR>   The challenge rating of the creature.
    -n=<num>            The number of times to generate loot (defaults to 1).
    -h --help           Show this screen.
    --version           Show version.
"""

const individual_0_4 = staticRead"../tables/individual-0-4.csv"
const individual_5_10 = staticRead"../tables/individual-5-10.csv"
const individual_11_16 = staticRead"../tables/individual-11-16.csv"
const individual_17_up = staticRead"../tables/individual-17-up.csv"

# TODO: move the table stuff into separate file

type
    Coins = object
        cp: uint
        sp: uint
        ep: uint
        gp: uint
        pp: uint

    Valuable = object
        value: uint
        description: string

    Treasure = object
        coins: Coins
        gems: Table[Valuable, uint8]
        art:  Table[Valuable, uint8]
        magic: Table[Valuable, uint8]

proc stripIndex(line: string): string =
    substr(line, find(line, ",")+1)

proc isSelected(line: string, d:int): bool =
    let lowHigh = substr(line, 0, find(line, ",")-1).split("-")
    d >= parseInt(lowHigh[0]) and d <= parseInt(lowHigh[1])

proc select(treasureTable: string, d: int): string =
      var selectedLine = "?"
      var strm = newStringStream(treasureTable)

      # skip the header
      discard strm.readLine()

      for line in lines(strm):
          if (not isEmptyOrWhitespace(line)) and isSelected(line, d):
              selectedLine = stripIndex(line)
              break
      strm.close()
      return selectedLine

proc rollForItem(defn: string): uint =
    if defn == "-":
        return 0
    else:
        let diceMult = defn.split("x")
        let rolled = roll(diceMult[0])
        let multiplier = if diceMult.len > 1: parseInt(diceMult[1]) else: 1
        return (rolled.value * multiplier).uint

proc rollIndividual(cr:uint8): Treasure =
    let selectedTable = if cr < 5:
        individual_0_4
    elif cr < 11:
        individual_5_10
    elif cr < 17:
        individual_11_16
    else:
        individual_17_up

    let d100 = rolling(1, 100, 0).value
    let selectedLine = select(selectedTable, d100)
    let parts = selectedLine.split(",")
    result.coins = Coins(
        cp: rollForItem(parts[0]),
        sp: rollForItem(parts[1]),
        ep: rollForItem(parts[2]),
        gp: rollForItem(parts[3]),
        pp: rollForItem(parts[4]),
    )
    return result

proc includeItem(): bool =
    rolling(1, 2, 0).value == 1

proc rollCoins(dice: string): Treasure =
    result.coins = Coins(
        cp: if includeItem(): rollForItem(dice) else: 0,
        sp: if includeItem(): rollForItem(dice) else: 0,
        ep: if includeItem(): rollForItem(dice) else: 0,
        gp: if includeItem(): rollForItem(dice) else: 0,
        pp: if includeItem(): rollForItem(dice) else: 0
    )

let args = docopt(doc, version = "Lootgen v0.1.0")

let n = if args["-n"]: parseInt($args["-n"]) else: 1

if args["individual"]:
    let cr = parseUInt($args["--cr"]).uint8
    for x in 0..(n-1):
        echo rollIndividual(cr)

elif args["coins"]:
    let dice = $args["<dice>"]
    for x in 0..(n-1):
        echo rollCoins(dice)
