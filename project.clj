(def tk-version "0.3.8")
(def ks-version "0.5.3")

(defproject puppetlabs/razor-server "2.0.0"
  :description "Puppet Razor Server"
  ;; Abort when version ranges or version conflicts are detected in
  ;; dependencies. Also supports :warn to simply emit warnings.
  ;; requires lein 2.2.0+.
  :pedantic? :abort
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [org.clojure/tools.logging "0.2.6"]
                 [puppetlabs/trapperkeeper ~tk-version]
                 [puppetlabs/kitchensink ~ks-version :exclusions [joda-time]]

                 ;; we are excluding some of the transitive jnr dependencies because they use
                 ;; version ranges, and lein doesn't like that, and we don't need them.
                 ;; we are excluding joni because jruby 1.7.9 has a dependency on a SNAPSHOT
                 ;; version of joni that doesn't exist anymore, and there is a released version
                 ;; available now.
                 [org.jruby/jruby "1.7.19" :exclusions [com.github.jnr/jffi com.github.jnr/jnr-x86asm org.jruby.joni/joni]]
                 ;; here we add back in the dependency on the non-SNAPSHOT version of joni.  We
                 ;; exclude jcodings because jruby already has a dependency on a newer version of it.
                 [org.jruby.joni/joni "2.1.1" :exclusions [org.jruby.jcodings/jcodings]]
                 ;; This line restricts which version of rack we can use in our app.
                 [org.jruby.rack/jruby-rack "1.1.20" :exclusions [org.jruby/jruby-complete]]
                 [com.github.jnr/jffi "1.2.9"]]

  :repositories [["releases" "http://nexus.delivery.puppetlabs.net/content/repositories/releases/"]
                 ["snapshots" "http://nexus.delivery.puppetlabs.net/content/repositories/snapshots/"]]

  :source-paths ["src/clojure"]
  :test-paths   ["test/clojure"]

  :target-path "target/%s/"
  :clean-targets ^{:protect false} [:target-path]

  :profiles {:dev {:test-paths ["test-resources"]
                   :dependencies [[puppetlabs/trapperkeeper-webserver-jetty9 "0.3.5"]
                                  [puppetlabs/trapperkeeper ~tk-version :classifier "test"]]}
             :test {:dependencies [[puppetlabs/kitchensink ~ks-version :classifier "test"]]}}

  :main puppetlabs.trapperkeeper.main
  )
