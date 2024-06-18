This is a collection of scripts and other miscellanea I've written.

**smart-ad-pw-change.rb**

A Ruby script to get around Active Directory password history restrictions. As far as I can tell, AD has a finite prior history of previous passwords. So this script changes your password to a configurable number of random passwords and then back to your original password.

2024 note: For anyone still using Active Directory, many configurations work around this by enforcing a minimum time between password changes and other such defenses. Bummer.

**sort-media.rb**

A Ruby script to sort photos and videos, given a flat source directory, into photos and videos destination directories organized by year and month.

**rentvine-to-stessa.rb**

Heavily customized for my purposes, but this takes a Rentvine (property management software/portal) ledger and converts it to the CSV format that Stessa can import.
You will need to export the Rentvine HTML ledger as CSV using the excellent [Download Table as CSV Plugin](https://chromewebstore.google.com/detail/download-table-as-csv/jgeonblahchgiadgojdjilffklaihalj?hl=en) since Rentvine doesn't support CSV export as of June 2024.
