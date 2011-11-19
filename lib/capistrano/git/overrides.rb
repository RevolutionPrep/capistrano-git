# OVERRIDES
Capistrano::Configuration.instance.load do
  namespace :deploy do
    desc <<-DESC
      Deploys your project. This calls both `update' and `restart'. Note that \
      this will generally only work for applications that have already been deployed \
      once. For a "cold" deploy, you'll want to take a look at the `deploy:cold' \
      task, which handles the cold start specifically.
    DESC
    task :default do
      update
      restart
    end

    desc <<-DESC
      Prepares one or more servers for deployment. Before you can use any \
      of the Capistrano deployment tasks with your project, you will need to \
      make sure all of your servers have been prepared with `cap deploy:setup'.
    DESC
    task :setup, :except => { :no_release => true } do
      strategy.setup!
    end

    desc <<-DESC
      Copies your project to the remote servers. This is the first stage \
      of any deployment; moving your updated code and assets to the deployment \
      servers. You will rarely call this task directly, however; instead, you \
      should call the `deploy' task (to do a complete deploy) or the `update' \
      task (if you want to perform the `restart' task separately).

      You will need to make sure you set the :scm variable to the source \
      control software you are using (it defaults to :subversion), and the \
      :deploy_via variable to the strategy you want to use to deploy (it \
      defaults to :checkout).
    DESC
    task :update_code, :except => { :no_release => true } do
      on_rollback { strategy.rollback! }
      strategy.deploy!
      finalize_update
    end

    task :finalize_update, :except => { :no_release => true } do
    end

    task :symlink, :except => { :no_release => true } do
    end

    namespace :bundle do
      desc "Wipe out and rebuild the existing bundle."
      task :rebuild do
        strategy.rebuild_bundle!
      end
    end

    desc <<-DESC
      Copy files to the currently deployed version. This is useful for updating \
      files piecemeal, such as when you need to quickly deploy only a single \
      file. Some files, such as updated templates, images, or stylesheets, \
      might not require a full deploy, and especially in emergency situations \
      it can be handy to just push the updates to production, quickly.

      To use this task, specify the files and directories you want to copy as a \
      comma-delimited list in the FILES environment variable. All directories \
      will be processed recursively, with all files being pushed to the \
      deployment servers.

        $ cap deploy:upload FILES=templates,controller.rb

      Dir globs are also supported:

        $ cap deploy:upload FILES='config/apache/*.conf'
    DESC
    task :upload, :except => { :no_release => true } do
      files = (ENV["FILES"] || "").split(",").map { |f| Dir[f.strip] }.flatten
      abort "Please specify at least one file or directory to update (via the FILES environment variable)" if files.empty?

      files.each { |file| top.upload(file, File.join(current_path, file)) }
    end

    desc <<-DESC
      Restarts your application. This works by calling the script/process/reaper \
      script under the current path.

      If you are deploying a Rails 2.3.x application, you will need to install \
      these http://github.com/rails/irs_process_scripts (more info about why \
      on that page.)

      By default, this will be invoked via sudo as the `app' user. If \
      you wish to run it as a different user, set the :runner variable to \
      that user. If you are in an environment where you can't use sudo, set \
      the :use_sudo variable to false:

        set :use_sudo, false
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      strategy.restart!
    end

    namespace :rollback do
      desc <<-DESC
        Will rollback to the last tagged revision.
      DESC
      task :revision, :except => { :no_release => true } do
        strategy.rollback!
      end

      task :cleanup, :except => { :no_release => true } do
      end

      desc <<-DESC
        Rolls back to the previously deployed version. You'll generally want \
        to call `rollback' instead, as it performs a `restart' as well.
      DESC
      task :code, :except => { :no_release => true } do
        revision
        cleanup
      end

      desc <<-DESC
        Rolls back to a previous version and restarts. This is handy if you ever \
        discover that you've deployed a lemon; `cap rollback' and you're right \
        back where you were, on the previously deployed version.
      DESC
      task :default do
        revision
        restart
        cleanup
      end
    end

    desc <<-DESC
      Migrates the DB.
    DESC
    task :migrate, :roles => :db, :only => { :primary => true } do
      strategy.migrate!
    end

    desc <<-DESC
      Deploy and run pending migrations. This will work similarly to the \
      `deploy' task, but will also run any pending migrations (via the \
      `deploy:migrate' task). Note that the update in this case it is not \
      atomic, and transactions are not used, because migrations are not \
      guaranteed to be reversible.
    DESC
    task :migrations do
      update_code
      migrate
      symlink
      restart
    end

    task :cleanup, :except => { :no_release => true } do
    end

    task :check, :except => { :no_release => true } do
    end

    desc <<-DESC
      Deploys and starts a `cold' application. This is useful if you have not \
      deployed your application before, or if your application is (for some \
      other reason) not currently running. It will deploy the code, run any \
      pending migrations, and then instead of invoking `deploy:restart', it will \
      invoke `deploy:start' to fire up the application servers.
    DESC
    task :cold do
      update
      migrate
      start
    end

    desc <<-DESC
      Start the application servers. \

      By default, the script will be executed via sudo as the `app' user. If \
      you wish to run it as a different user, set the :runner variable to \
      that user. If you are in an environment where you can't use sudo, set \
      the :use_sudo variable to false.
    DESC
    task :start, :roles => :app do

    end

    desc <<-DESC
      Stop the application servers. \

      By default, the script will be executed via sudo as the `app' user. If \
      you wish to run it as a different user, set the :runner variable to \
      that user. If you are in an environment where you can't use sudo, set \
      the :use_sudo variable to false.
    DESC
    task :stop, :roles => :app do

    end

    namespace :pending do
      task :diff, :except => { :no_release => true } do
      end

      task :default, :except => { :no_release => true } do
      end
    end

    namespace :web do
      task :disable, :roles => :web, :except => { :no_release => true } do
      end
      task :enable, :roles => :web, :except => { :no_release => true } do
      end
    end
  end
end
