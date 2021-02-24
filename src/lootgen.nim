import docopt, tables, hashes, strutils, parseutils, random
import polydicepkg/dice
import gametablespkg/tableselector
import streams, strutils

randomize()

let doc = """
A tool for generating random 5e treasure.

Usage:
    lootgen individual [-n=<num>] (-c=<CR> | --cr=<CR>)
    lootgen hoard [-n=<num>] (-c=<CR> | --cr=<CR>)
    lootgen coins [-n=<num>] <dice>
    lootgen art [-n=<num>] [25 | 250 | 750 | 2500 | 7500]
    lootgen gems [-n=<num>] [10 | 50 | 100 | 500 | 1000 | 5000]
    lootgen magic [-n=<num>] [<table>]
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

const art_25 = staticRead"../tables/art-25gp.csv"
const art_250 = staticRead"../tables/art-250gp.csv"
const art_750 = staticRead"../tables/art-750gp.csv"
const art_2500 = staticRead"../tables/art-2500gp.csv"
const art_7500 = staticRead"../tables/art-7500gp.csv"

const gems_10 = staticRead"../tables/gems-10gp.csv"
const gems_50 = staticRead"../tables/gems-50gp.csv"
const gems_100 = staticRead"../tables/gems-100gp.csv"
const gems_500 = staticRead"../tables/gems-500gp.csv"
const gems_1000 = staticRead"../tables/gems-1000gp.csv"
const gems_5000 = staticRead"../tables/gems-5000gp.csv"

const magic_a = staticRead"../tables/magic-A.csv"
const magic_b = staticRead"../tables/magic-B.csv"
const magic_c = staticRead"../tables/magic-C.csv"
const magic_d = staticRead"../tables/magic-D.csv"
const magic_e = staticRead"../tables/magic-E.csv"
const magic_f = staticRead"../tables/magic-F.csv"
const magic_g = staticRead"../tables/magic-G.csv"
const magic_h = staticRead"../tables/magic-H.csv"
const magic_i = staticRead"../tables/magic-I.csv"

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


proc hash(x: Valuable): Hash =
    result = x.description.hash

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

    let selectedLine = selectRowLine(selectedTable)
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

proc rollArt(artTable: string, artValue: uint): Treasure =
    let selectedItem = selectRowLine(artTable)
    result.art = {
        Valuable(value: artValue, description: selectedItem): 1.uint8
    }.toTable

proc rollGems(gemTable: string, gemValue: uint): Treasure =
    let selectedItem = selectRowLine(gemTable)
    result.gems = {
        Valuable(value: gemValue, description: selectedItem): 1.uint8
    }.toTable

proc rollMagic(magicTable: string): Treasure =
    let selectedItem = selectRowLine(magicTable)
    result.magic = {
        Valuable(description: selectedItem): 1.uint8
    }.toTable

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

elif args["art"]:
    let artTables = {
        25: art_25,
        250: art_250,
        750: art_750,
        2500: art_2500,
        7500: art_7500
    }.toTable

    var artValue = if args["25"]: 25
    elif args["250"]: 250
    elif args["750"]: 750
    elif args["2500"]: 2500
    elif args["7500"]: 7500
    else: sample({25, 250, 750, 2500, 7500})

    for x in 0..(n-1):
        echo rollArt(artTables[artValue], artValue.uint)

elif args["gems"]:
    let gemTables = {
        10: gems_10,
        50: gems_50,
        100: gems_100,
        500: gems_500,
        1000: gems_1000,
        5000: gems_5000
    }.toTable

    let gemValue = if args["10"]: 10
    elif args["50"] : 50
    elif args["100"]: 100
    elif args["500"]: 500
    elif args["1000"]: 1000
    elif args["5000"]: 5000
    else: sample({10, 50, 100, 500, 1000, 5000})

    let gemTable = gemTables[gemValue]
    for x in 0..(n-1):
        echo rollGems(gemTable, gemValue.uint)

elif args["magic"]:
    let magicTables = {
        "a": magic_a,
        "b": magic_b,
        "c": magic_c,
        "d": magic_d,
        "e": magic_e,
        "f": magic_f,
        "g": magic_g,
        "h": magic_h,
        "i": magic_i
    }.toTable

    let magicTable = if args["<table>"]: $args["<table>"] else: sample(["a", "b", "c", "d", "e", "f", "g", "h", "i"])

    for x in 0..(n-1):
        echo rollMagic(magicTables[magicTable])
