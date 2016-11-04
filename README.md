<h1 align="center">Atlas</h1>
<p align="center">Object Mapper for ETSource Data</p>

<p align="center">
  <a href="https://travis-ci.org/quintel/atlas"><img alt="Master branch build status" src="https://img.shields.io/travis/quintel/atlas/master.svg" /></a>

  <a href="https://codecov.io/gh/quintel/atlas"><img alt="Code coverage status" src="https://img.shields.io/codecov/c/github/quintel/atlas/master.svg" /></a>
</p>

Atlas is a Ruby library for interacting with the ETSource data. It provides the
means to easily read, write, and delete ETSource ".ad" files and is also
responsible for converting the documents into a format which can be used by
ETEngine.

### Setting Up Atlas

In order to run Atlas, you will need to check out a copy of both the Atlas and
ETSource repositories, and install Atlas' dependencies. It is recommended –
but not required – that both repositories are cloned into a common parent
directory. In this example, we're going to put them both in "~/code":

```sh
$ cd ~/code
$ git clone git@github.com:quintel/atlas.git
$ git clone git@github.com:quintel/etsource.git

$ ls
etsource   atlas
```

We now need to install Atlas's dependencies using Bundler:

```sh
$ cd atlas
$ bundle install
```

Once this has completed, you're ready to go!

### Using The Atlas Console

The console provides the ability to use Atlas' classes directly to create,
edit, and delete ETSource documents. Start the console with the
`rake console` command:

```sh
$ cd ~/code/atlas
$ rake console
=> "../etsource/data"
```

When in the console, the full range of document classes are available for you
to use:

* **Atlas::Carrier**
* **Atlas::Dataset** – Also provides access to data such as energy balances,
  edge shares, and CHP data.
* **Atlas::Edge** – In the past known as "links".
* **Atlas::Gquery**
* **Atlas::Input**
* **Atlas::Node** – ... and the subclasses Converter, DemandNode, StatNode,
  and FinalDemandNode.
* **Atlas::Preset**
* **Atlas::Slot**

These classes behave similarly to records in Rails applications:

```ruby
# Fetch all Gqueries:
Atlas::Gquery.all

# Fetch a specific input:
Atlas::Input.find(:bio_ethanol_from_cane_sugar_share)
```

You can also edit all the attributes on the documents:

```ruby
input = Atlas::Node.find(:households_collective_chp_biogas)
# => #<Atlas::ConverterNode :households_collective_chp_biogas>

input.energy_balance_group = 'household CHPs'
input.save
# => true
```

Changing a document key will automatically rename the file:

```ruby
input.key = :households_collective_chp_greengas

# Renames the file from: households_collective_chp_biogas.converter.ad
#                    to: households_collective_chp_greengas.converter.ad
input.save
```

`save` will return false if validation failed; if this happens, you will need
to correct the validation errors before saving again. `save!` will complain
more loudly if validation fails by raising an exception and showing you the
errors.

#### Other Useful Helpers

* Find out where a document is stored by calling `path`.
* Delete a document with `destroy!`
* Skip validation and forcefully save an invalid document with `save(false)`.
* Update attributes and save in one step with `update_attributes`.
* Documents can be saved in subdirectories and Atlas will load them anyway.
  The subdirectory indicates a "namespace" for the document which can be
  accessed by calling `ns`. Normally, document namespaces have no
  significance, but in some cases they might (e.g. for nodes, the namespace
  indicates the "sector" to which the node belongs; nodes in a "households"
  subdirectory belong to the "households" sector).

#### Custom ETSource Paths

Note how the first line of output when starting the console shows the ETSource
data directory, "../etsource/data". If you cloned ETSource to a different
location, you will need to specify the path when running `rake console` by
providing it in square brackets:

```sh
$ rake console[../my/custom/dir]
=> "../my/custom/dir"
```

Relative paths (beginning with "..") are permitted, but the tilde character
("~") is not; if you need to refer to your user home directory, you should
provide the full expanded path:

```sh
$ rake console[/Users/drtobiasfunke/data]
=> "/Users/drtobiasfunke/data"
```

Finally, there must be no spaces anywhere between the "c" which begins
"console" and the closing square bracket. If your path contains spaces,
you need to wrap the whole thing in quotes:

```sh
$ rake "console[/tmp/a whole thing of candy beans]"
=> "/tmp/a whole thing of candy beans"
```

### Building ETSource for ETEngine

Not yet supported, but in the near future it will be possible to use Atlas to
build files to be used by ETEngine. This involves taking the ".ad" files and a
region code (such as "nl"), performing the queries in each document using data
from the chosen region, then handing the partially-calculated graph to
[Refinery][refinery] to fill in the remaining demands and edge shares.

#### Testing a Subgraph

It is possible to test a subgraph already; this selects nodes which match a
chosen sector, sets their demands and shares, and performs the Refinery
calculation step. The results are shown in your terminal, with "before" and
"after" images output to the ./atlas/tmp directory.

```sh
$ cd ~/code/atlas
$ rake debug:graph
```

If your ETSource directory is not at the same location as your Atlas
directory, you need to specify the pato the ETSource:

```sh
$ rake debug:graph[../somewhere/else/etsource/data]
```

Like the "console" task, there must be absoluely no spaces unless you surround
the rake command in quotes:

```sh
$ rake "debug:graph[/tmp/the gothic castle]"
```

#### Production Mode

Production mode loads Atlas using pre-calculated node demands and edge shares
(see "Building ETSource for ETEngine"). Production mode is not yet
implemented, but will be added once ETEngine build support is ready.

Prior to loading Atlas, a `ATLAS_ENV` environment variable must be set:

```ruby
ENV['ATLAS_ENV'] = :production
require 'atlas'
```

### Importing "Legacy" ETSource Files

The conversion from all the old "legacy" ETSource files to the new
ActiveDocument format is not yet complete, and some document files need to be
recreated when the old files are updated. For example, when a new edge is
added in InputExcel, an ".ad" file needs to be created also.

As it would be far too laborious to do this by hand every time, there are
Rake tasks to perform the import of old files to new. Each takes two
arguments: the path to the ETSource repository, and the path to the ETSource
"data" directory:

```sh
$ cd ~/code/atlas
$ rake import:nodes[../etsource,../etsource/data]
```

This will recreate all of the Node ".ad" files with the latest data. There
also exists "import:carriers", "import:edges", and "import:presets".
Alternatively, you can do all at once by running `rake import`. **Do not** run
an import if your ETSource repository has uncommitted changes.

After running an import, you should change to the ETSource directory to
commit the updated files and remove those which have been deleted.

[refinery]: https://github.com/quintel/refinery
