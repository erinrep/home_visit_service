# HomeVisitService

An app to allow users to register for an account and then request visits as a member or fulfill visits as a pal.

## Requirements
### Requires Elixir 1.16.2 and OTP 26

Install with brew
`brew install elixir`
or visit [elixir-lang.org](https://elixir-lang.org/install.html) for other installation options

### Requires Postgres 2.6.2

Visit [postgresql.org](https://www.postgresql.org/download/) for installation options

## Setup
To start the server:

  * Run `mix setup` to install and setup dependencies and the Postgres database
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing
Run `mix test` to run unit tests

## Design Choices
- Relied on Phoenix generators to help get up and running quickly with bare bones ui
- Give users 30 minutes when they register
- Implement user balance as integer, use floor when performing calculations
- Store dates in the database as utc
- Users can edit or delete their requested visits until they have been accepted by a pal

## Next Steps
- Do not allow users to request visits until they have verified their email address
- Convert local time to utc on form submission
- Create admin users with ability to perform admin actions. For example:
  - Update the registration balance amount in order to hold sign up promotions
  - Gift minutes?
- Idea: Allow members to reject an accepted visit
- set up CI to run tests and formatter for PRs


