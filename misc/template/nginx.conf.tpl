
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
error_log {{OPENSHIFT_HOMEDIR}}/app-root/logs/nginx_error.log debug;

pid        {{NGINX_DIR}}/logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;
    #access_log $OPENSHIFT_DIY_LOG_DIR/access.log main;
    port_in_redirect off;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  165;

    gzip  on;
	
	upstream frontends {
        #server pr4ss.tk;
        #server 222.66.115.233:80 weight=1;
		server {{OPENSHIFT_INTERNAL_IP}}:8081 ;
		
    }
	upstream frontends2 {
        server google.com;
        #server 222.66.115.233:80 weight=1;
		#server {{OPENSHIFT_INTERNAL_IP}}:8081 ;
		
    }
	upstream index {
        
		server {{OPENSHIFT_INTERNAL_IP}}:15001 weight=1;
		server {{OPENSHIFT_INTERNAL_IP}}:15002 weight=2;
		server {{OPENSHIFT_INTERNAL_IP}}:15002 weight=3;
		
    }

    server {
        listen      {{OPENSHIFT_INTERNAL_IP}}:{{OPENSHIFT_INTERNAL_PORT}};
        server_name  {{OPENSHIFT_GEAR_DNS}} {{www.OPENSHIFT_GEAR_DNS}};
		root {{OPENSHIFT_REPO_DIR}};


		set_real_ip_from {{OPENSHIFT_INTERNAL_IP}};
		real_ip_header X-Forwarded-For;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   {{OPENSHIFT_REPO_DIR}};
            index  index.html index.htm;
			try_files $uri $uri/ =404;
			
			autoindex on;
			autoindex_exact_size off;
			autoindex_localtime on;
            
            #proxy_set_header Authorization base64_encoding_of_"user:password";
			#proxy_pass_header Server;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_set_header  X-Real-IP  $remote_addr;
            proxy_set_header X-Scheme $scheme;

        }
		location /www {
            #root   {{OPENSHIFT_REPO_DIR}};
            index  index.html index.htm;
			
			autoindex on;
			autoindex_exact_size off;
			autoindex_localtime on;
            
            #proxy_set_header Authorization base64_encoding_of_"user:password";
			#proxy_pass_header Server;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_set_header  X-Real-IP  $remote_addr;
            proxy_set_header X-Scheme $scheme;
            proxy_pass http://frontends;
        }
		location /categories {
            #root   {{OPENSHIFT_REPO_DIR}};
            index  index.html index.htm;
			
			autoindex on;
			autoindex_exact_size off;
			autoindex_localtime on;
            
            #proxy_set_header Authorization base64_encoding_of_"user:password";
			#proxy_pass_header Server;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_set_header  X-Real-IP  $remote_addr;
            proxy_set_header X-Scheme $scheme;
            proxy_pass http://frontends2;
        }
		location /index {
            #root   {{OPENSHIFT_REPO_DIR}};
            index  index.html index.htm;
			
			autoindex on;
			autoindex_exact_size off;
			autoindex_localtime on;
			# an HTTP header important enough to have its own Wikipedia entry:
			#   http://en.wikipedia.org/wiki/X-Forwarded-For
			proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header   Host             $host;
            proxy_set_header   X-Real-IP        $remote_addr;

	
			# enable this if you forward HTTPS traffic to unicorn,
			# this helps Rack set the proper URL scheme for doing redirects:
			# proxy_set_header X-Forwarded-Proto $scheme;
	
			# pass the Host: header from the client right along so redirects
			# can be set properly within the Rack application
			proxy_set_header Host $http_host;

			# we don't want nginx trying to do something clever with
			# redirects, we set the Host: header above already.
			proxy_redirect off;
	
			# set "proxy_buffering off" *only* for Rainbows! when doing
			# Comet/long-poll/streaming.  It's also safe to set if you're using
			# only serving fast clients with Unicorn + nginx, but not slow
			# clients.  You normally want nginx to buffer responses to slow
			# clients, even with Rails 3.1 streaming because otherwise a slow
			# client can become a bottleneck of Unicorn.
			#
			# The Rack application may also set "X-Accel-Buffering (yes|no)"
			# in the response headers do disable/enable buffering on a
			# per-response basis.
			# proxy_buffering off;
	
			
		



            client_max_body_size       10m;
            client_body_buffer_size    128k;

            proxy_connect_timeout      10;
            proxy_send_timeout         5;
            proxy_read_timeout         3600;

            proxy_buffer_size          4k;
            proxy_buffers              4 132k;
            proxy_busy_buffers_size    264k;
            proxy_temp_file_write_size 164k;
			proxy_pass http://index;			

            
            #proxy_set_header Authorization base64_encoding_of_"user:password";
			#proxy_pass_header Server;
            proxy_set_header Host $http_host;
        }
		
		

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        location ~ \.php$ {
            root           html;
            fastcgi_pass   {{OPENSHIFT_INTERNAL_IP}}:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            include        fastcgi_params;
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443;
    #    server_name  localhost;

    #    ssl                  on;
    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_timeout  5m;

    #    ssl_protocols  SSLv2 SSLv3 TLSv1;
    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers   on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
