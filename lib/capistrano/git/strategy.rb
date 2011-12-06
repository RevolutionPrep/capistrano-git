require 'capistrano/recipes/deploy/strategy/base'

module Capistrano
  module Deploy
    module Strategy

      class Awesome < Base

        def setup!
          run "sudo rm -rf #{configuration[:deploy_to]}"
          run "sudo mkdir -p #{configuration[:deploy_to]} && sudo chown -R #{configuration[:passenger_user]}:#{configuration[:passenger_user]} #{configuration[:deploy_to]}"
          run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} git clone #{configuration[:repository]} ."
          run "sudo mkdir -p #{configuration[:deploy_to]}/log && sudo mkdir -p #{configuration[:deploy_to]}/tmp"
          deploy_no_tag
        end

        def check!

        end

        def deploy!
          puts "\n\n### DEPLOY!: Deploying...\n\n"
          unless @tag_created
            create_tag
            @tag_created = true
          end
          get_tag
          deploy_no_tag
        end

        def rollback!
          puts "\n\n### ROLLBACK!: Rolling back...\n\n"
          unless @got_tag
            get_tag
            @got_tag = true
          end
          run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} git checkout ."
          run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} git checkout #{@tag}"
        end

        def migrate!
          puts "\n\n### MIGRATE!: Migrating...\n\n"
          run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} git checkout #{configuration[:branch]}"
          run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} git pull"
          rake_command = configuration[:without_bundler] ? "#{configuration[:ruby_bin_dir]}/rake" : "#{configuration[:ruby_bin_dir]}/bundle exec rake"
          run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} #{rake_command} db:migrate --trace RAILS_ENV=#{configuration[:rails_env]}"
        end

        def restart!
          puts "\n\n### RESTART!: Restarting the Passengers...\n\n"
          run "sudo chown -R #{configuration[:passenger_user]}:#{configuration[:passenger_group]} #{configuration[:deploy_to]}"
          run "sudo touch #{configuration[:deploy_to]}/tmp/restart.txt"
        end

        protected

          def create_tag
            puts "\n\n### CREATE TAG: Tagging the current version before updating...\n\n"
            @tag = "#{configuration[:application]}_#{Time.now.strftime("%Y%m%d%H%M%S")}"
            run "cd #{configuration[:deploy_to]} &&  sudo -u #{configuration[:sudo_user]} git tag #{@tag}", :roles => :app, :only => { :primary => true }
            run "cd #{configuration[:deploy_to]} &&  sudo -u #{configuration[:sudo_user]} git push --tags", :roles => :app, :only => { :primary => true }
            # Create an empty file with our tag name, so we can easily go grab the tagname for rollback
            run "sudo rm -f #{File.join(configuration[:latest_tag_dir], '*')}"
            run "sudo mkdir -p #{configuration[:latest_tag_dir]}"
            run "sudo touch #{File.join(configuration[:latest_tag_dir], @tag)}"
            puts "\nSetting latest tag as #{@tag}\n"
          end

          def get_tag
            puts "\n\n### GET TAG: Retrieving the latest version...\n\n"
            run "ls " + File.join(configuration[:latest_tag_dir]).to_s, :roles => :app, :only => { :primary => true } do |ch, stream, data|
              if stream == :err
                puts "capured output on STDERR: #{data}"
              else # stream == :out
                data = data.strip
                @tag = data
                puts "\nLatest tag is #{@tag}\n\n"
              end
            end
          end

          def deploy_no_tag
            puts "\n\n### DEPLOY NO TAG: Deploying to #{configuration[:stage]} at #{configuration[:deploy_to]}\n\n"
            run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} git checkout . && sudo -u #{configuration[:sudo_user]} git checkout #{configuration[:branch]}" # make sure we're on the right branch
            run "cd #{configuration[:deploy_to]} && sudo -u #{configuration[:sudo_user]} git pull" # get head
          end

      end

    end
  end
end
