# Running RSpec examples

Commands for running examples:

 * __Run Examples__ <kbd>⌘R</kbd>: Run all examples in the current spec file.
 * __Run Single Example__ <kbd>⇧⌘R</kbd>: Run the example on the current line (also works for example groups).
 * __Run Single Example in Terminal__ <kbd>⇧⌘R</kbd>: Same as above, but runs RSpec in a terminal window. This is especially useful if you need to interact with the RSpec process because you’re debugging using `pry` or `byebug`.
 * __Run Examples in Selected Files__ <kbd>⌥⇧⌘R</kbd>: Run all examples from the files / directories selected in the file browser. If nothing is selected, run all examples in `spec/`. Hint: <kbd>⇧⌘A ⌥⇧⌘R</kbd> is a quick way to run all specs (<kbd>⇧⌘A</kbd> deselects everything in the file browser).
 * __Run Failed Examples in Selected Files__ <kbd>⌥⇧⌘R</kbd>: Same as above, but only run examples that failed previously (using [`--only-failures`](https://relishapp.com/rspec/rspec-core/v/3-6/docs/command-line/only-failures)).
 * __Run Again__ <kbd>⌃⌥⌘R</kbd>: Repeat the last run command (can be example file, single example or examples in selected files).
 
If your project has an `.rspec` file in its root, the last two commands – “Run Examples in Selected Files/Directories” and “Run Again” – are available everywhere in your project (even in files that not using the “RSpec” mode).
 
# How RSpec is run

The bundle runs RSpec in a subshell. The command to start RSpec is determined as such:

 * If a binstub (`bin/rspec`) is present, it is used for running RSpec (this works great for preloaders like [Spring](https://github.com/rails/spring), too).
 * If there is no binstub, but `Gemfile.lock` is present, RSpec is run via `bundle exec rspec`.
 * If there is neither a binstub nor a `Gemfile.lock`, RSpec is simply run via `rspec` (__not recommended__ – use only if you know exactly what you’re doing).

Internally the bundle uses `Executable.find` from the Ruby bundle to detect how to run RSpec. For details see https://github.com/textmate/ruby.tmbundle/blob/master/Support/lib/executable.rb

Running RSpec / Ruby from a subshell means that TextMate must be configured to work with whatever Ruby version manager you're using ([rbenv](https://github.com/sstephenson/rbenv), [rvm](http://rvm.io/), …). Normally, this means customizing the `$PATH` variable. See [Defining a $PATH](http://blog.macromates.com/2014/defining-a-path/) in the TextMate blog for details and caveats.

## Setting the base directory for running examples

Per default, RSpec is run from the directory currently designated as “project folder” in TextMate. This can be overriden by setting `TM_RSPEC_BASEDIR`.

It’s even possible to have different base directories for running RSpec in a single project. Take for example a Rails Engine with the following directory layout:


    app/        # Rails app
    spec/       # examples for the Rails app
    my_engine/
      app/      # Engine
      spec/     # examples for the Engine

The examples for the Rails app should be run from the top-level directory, but the examples for the Engine should be run from `my_engine/`.

To achieve this, create a file `my_engine/.tm_properties` with the following line:

    TM_RSPEC_BASEDIR=$CWD

This makes sure that `TM_RSPEC_BASEDIR` is set to the full path of the `my_engine/` directory whenever you’re editing a file in this directory (or one of its subdirectories). So if you’re editing  `my_engine/spec/foo_spec.rb` and press <kbd>⌘R</kbd> to run the examples, they will be run from the `my_engine/` directory, while running examples in, say, `spec/bar_spec.rb` are still run from the top-level project directory.

# Configuration

In addition to the standard TextMate shell variables, the RSpec
TextMate bundle supports the following:

## TM\_RSPEC\_BASEDIR

Set the base directory for running RSpec (defaults to the current “Project Folder”). See “Setting the base directory for running examples” above for more info and an example.

## TM\_RSPEC\_FORMATTER

Set a custom formatter other than RSpec's TextMate formatter. Use
the full classname, e.g. `'Spec::Core::Formatters::WebKit'`

## TM\_RSPEC\_OPTS

Use this to set RSpec options just as you would in an `.rspec`
file.

## TM\_TERMINAL\_USE\_TABS

If set, “Run Single Example in Terminal” will open a new tab in an existing terminal window instead of creating a new terminal window. (This setting originates from the “Open Terminal” command in the Shell Script bundle).


# RVM Integration

[__NOTE: Information in this section may be outdated__]

There are lots of ways to configure TextMate to work with `rvm`,
but this is the one that we recommend:

With rvm installed, take the full path to `rvm-auto-ruby`, 
found via: `which rvm-auto-ruby`

Next, set up a `TM_RUBY` option in
`TextMate/Preferences/Advanced/Shell Variables` that points to the
`rvm-auto-ruby` command.

Learn more at:

* [http://rvm.io/integration/textmate](http://rvm.io/integration/textmate)
* [http://groups.google.com/group/rubyversionmanager/browse_thread/thread/64b84bbcdf49e9b?fwc=1&pli=1](http://groups.google.com/group/rubyversionmanager/browse_thread/thread/64b84bbcdf49e9b?fwc=1&pli=1)

