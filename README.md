# hticketiser

From YAML to Jira tickets. 

---

This is a reimplementation in Haskell of _the ticketiser_ I have been using at work for close to two years. That version is written in Python and it was a bit too complex to generalise. This one is not easy, but at least having a compiled language means tinkering with it to make it work is a bit less sensitive.

You can read a blog post about my experience using Haskell to write this project, since this is the first time I have written anything of any non-trivial size.

## Usage

Write a `tickets.yaml` file like

```yaml
- epic: Title goes here
  us: User story goes here
  ac: Acceptance criteria
- story: Title goes here
  us: You know the drill
  ac: All done
- story: There are some optional fields
  us: Like
  ac: Description as above
  desc: Or points, which should be a number
  pt: 34
```

Set up a file `~/.hticketiser.yaml` with

```yaml
path: https://yourjiracloudpath.atlassian.net
auth: as seen in Jira docs at [1]
```

[1] https://developer.atlassian.com/cloud/jira/platform/basic-auth-for-rest-apis/#getting-your-api-token

_Note_: The easiest way to get the properly encoded login token is to get an API token, use the `curl` example in the page linked above with the `-v` (verbose) flag. It will give you the properly encoded token for the API request without you needing to mess with the encodings.

Run 

```bash
hticketiser tickets.yaml
```

Profit of your time savings.

_Note_: By default this will go to project `11400` and team `12401`. You will need to tweak this unless you work on _my_ team and company.

_Additional note_: Stories after an epic go to the last-seen epic, starting from the top. Thus, you can chain creating several epics and the stories that go inside of each without any additional effort. If you want stories _outside_ of epics, put them on top of the file.

## Installation

```bash
git clone https://github.com/rberenguel/hticketiser
cd hticketiser
stack build  # Wait for a bit (…)
stack install
```

## FAQ/Problems you may encounter

#### Each Jira cloud is an island

Each Jira is set up differently. This means the mappings from field identifiers to API payloads (in [Jira.hs](src/Jira.hs) and [Tickets.hs](src/Tickets.hs)) need to be tweaked for your specific use case. There are some details in those files, but the summary is:

- Visit `https://yourjiracloudpath.atlassian.net/rest/api/2/issue/ISSUE IDENTIFIER`
- Modify `JiraMap` in `Jira.hs` to have the fields your Jira set up requires
- Tweak as needed in `Tickets.hs` to make sure the payloads are properly created
- Stack install and try as many times as needed.

It takes a while, the first time I had to do this I spent the best part of an afternoon cursing at Jira and figuring this out.

#### I hate Haskell

Well, if you can read it you can figure out how this works and reimplement it in your language of choice. It's a good beginner exercise for any language.

#### Why did you use YAML and not [Dhall](https://dhall-lang.org)?

😒

#### Why not just ignore Jira?

Well, planning projects requires writing tickets. In particular, there are some kind of tickets product owners can't write. The very technical in particular, and if I need to write them, I want to avoid as much as possible having to click in 25 different places and wait for a not-very-fast-API.