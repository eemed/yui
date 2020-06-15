let Prelude = https://prelude.dhall-lang.org/package.dhall

let Contact
    : Type
    = { name : Text, email : Text }

let Header
    : Type
    = { name : Text
      , author : Contact
      , maintainer : Contact
      , license : Text
      , lastUpdated : Text
      }

let renderHeader
    : Header → Text
    =   λ(h : Header)
      → ''
        " Name:            ${h.name}
        " Author:          ${h.author.name} <${h.author.email}>
        " Maintainer:      ${h.maintainer.name} <${h.maintainer.email}>
        " License:         ${h.license}
        " Last Updated:    ${h.lastUpdated}
        ''

let Background
    : Type
    = < light | dark >

let renderBackground
    : Background → Text
    = λ(b : Background) → merge { light = "light", dark = "dark" } b

let Color256
    : Type
    = Optional Natural

let renderColor256
    : Color256 → Text
    =   λ(c : Color256)
      → merge
          { None = "NONE", Some = λ(n : Natural) → Prelude.Natural.show n }
          c

let ColorBasic
    : Type
    = < darkred
      | red
      | darkgreen
      | green
      | darkyellow
      | yellow
      | darkblue
      | blue
      | darkmagenta
      | magenta
      | black
      | darkgrey
      | grey
      | white
      | NONE
      >

let renderColorBasic
    : ColorBasic → Text
    =   λ(c : ColorBasic)
      → merge
          { darkred = "darkred"
          , red = "red"
          , darkgreen = "darkgreen"
          , green = "green"
          , darkyellow = "darkyellow"
          , yellow = "yellow"
          , darkblue = "darkblue"
          , blue = "blue"
          , darkmagenta = "darkmagenta"
          , magenta = "magenta"
          , black = "black"
          , darkgrey = "darkgrey"
          , grey = "grey"
          , white = "white"
          , NONE = "NONE"
          }
          c

let NeovimStyle
    : Type
    = < bold | underline | reverse | italic | standout | NONE | undercurl >

let NeovimColorCustom
    : Type
    = { hex : Text, color256 : Color256, colorBasic : ColorBasic }

let renderNeovimColorCustomHex
    : NeovimColorCustom → Text
    = λ(c : NeovimColorCustom) → c.hex

let renderNeovimColorCustom256
    : NeovimColorCustom → Text
    = λ(c : NeovimColorCustom) → renderColor256 c.color256

let renderNeovimColorCustomBasic
    : NeovimColorCustom → Text
    = λ(c : NeovimColorCustom) → renderColorBasic c.colorBasic

let NeovimColor
    : Type
    = < Custom : NeovimColorCustom | NONE | fg | bg >

let renderNeovimColor
    : (NeovimColorCustom → Text) → NeovimColor → Text
    =   λ(extract : NeovimColorCustom → Text)
      → λ(c : NeovimColor)
      → merge { Custom = extract, NONE = "NONE", fg = "fg", bg = "bg" } c

let HighlightLink
    : Type
    = { group : Text, inheritFrom : Text }

let HighlightCreate
    : Type
    = { group : Text
      , background : NeovimColor
      , foreground : NeovimColor
      , style : NeovimStyle
      }

let Highlight
    : Type
    = < Link : HighlightLink | Create : HighlightCreate >

let renderHighlightForGUI
    : Highlight → Text
    =   λ(h : Highlight)
      → merge
          { Link = λ(r : HighlightLink) → "hi link ${r.group} ${r.inheritFrom}"
          , Create =
                λ(r : HighlightCreate)
              → let ctermbg =
                      renderNeovimColor renderNeovimColorCustom256 r.background

                let ctermfg =
                      renderNeovimColor renderNeovimColorCustom256 r.foreground

                let guibg =
                      renderNeovimColor renderNeovimColorCustomHex r.background

                let guifg =
                      renderNeovimColor renderNeovimColorCustomHex r.foreground

                in  "hi ${r.group} ctermbg=${ctermbg} ctermfg=${ctermfg} guibg=${guibg} guifg=${guifg}"
          }
          h

let Scheme
    : Type
    = { header : Header, background : Background, highlights : List Highlight }

let renderScheme
    : Scheme → Text
    =   λ(s : Scheme)
      → let header = renderHeader s.header

        let highlights =
              Prelude.Text.concatMapSep
                "\n"
                Highlight
                renderHighlightForGUI
                s.highlights

        in  ''
            ${header}

            set background=${renderBackground s.background}

            hi clear

            if exists("syntax_on")
              syntax reset
            endif

            let g:colors_name = '${s.header.name}'

            ${highlights}
            ''

let white =
      NeovimColor.Custom
        { hex = "#FFFFFF", color256 = Some 1, colorBasic = ColorBasic.darkred }

let normal =
      Highlight.Create
        { group = "Normal"
        , background = white
        , foreground = white
        , style = NeovimStyle.NONE
        }

let myself
    : Contact
    = { name = "Florian B", email = "yuuki@protonmail.com" }

let myHeader
    : Header
    = { name = "Yui"
      , author = myself
      , maintainer = myself
      , license = "Whatever"
      , lastUpdated = "Sun 21 Jul 2020 12:00:00 AM CEST"
      }

let myScheme
    : Scheme
    = { header = myHeader
      , background = Background.light
      , highlights = [ normal ]
      }

in  renderScheme myScheme
