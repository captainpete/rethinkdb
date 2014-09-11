# Copyright 2010-2012 RethinkDB, all rights reserved.
# TopBar view
module 'TopBar', ->
    class @Container extends Backbone.View
        className: 'sidebar-container'
        template: Handlebars.templates['sidebar-container-template']
        template_dataexplorer: Handlebars.templates['sidebar-dataexplorer_container-template']

        initialize: (data) =>
            @model = data.model
            @issues = data.issues

            @client_panel = new TopBar.ClientConnectionStatus
                model: @model
            @servers_panel = new TopBar.ServersConnected
                model: @model
            @tables_panel = new TopBar.TablesAvailable
                model: @model
            @issues_panel = new TopBar.Issues
                model: @model
            @issues_banner = new TopBar.IssuesBanner
                model: @model
                collection: @issues
                container: @

        render: =>
            @$el.html @template({})

            # Render connectivity status
            @$('.client-connection-status').html @client_panel.render().el
            @$('.servers-connected').html @servers_panel.render().el
            @$('.tables-available').html @tables_panel.render().el

            # Render issue summary and issue banner
            @$('.issues').html @issues_panel.render().el
            @$('.issues-banner').html @issues_banner.render().el

            @

        remove_parent_alert: (event) =>
            element = $(event.target).parent()
            element.slideUp 'fast', =>
                element.remove()
                @issues_being_resolved()
                @issues_banner.render()

        remove: =>
            @client_panel.remove()
            @servers_panel.remove()
            @tables_panel.remove()
            @issues_panel.remove()
            @issues_banner.remove()

    # TopBar.ClientConnectionStatus
    class @ClientConnectionStatus extends Backbone.View
        className: 'client-connection-status'
        template: Handlebars.templates['sidebar-client_connection_status-template']

        initialize: =>
            @listenTo @model, 'change:me', @render

        render: =>
            @$el.html @template
                disconnected: false
                me: @model.get 'me'
            @

        remove: =>
            @stopListening()
            super()

    # TopBar.ServersConnected
    class @ServersConnected extends Backbone.View
        template: Handlebars.templates['sidebar-servers_connected-template']

        initialize: =>
            @listenTo @model, 'change:num_servers', @render
            @listenTo @model, 'change:num_available_servers', @render

        render: =>
            @$el.html @template
                num_available_servers: @model.get 'num_available_servers'
                num_servers: @model.get 'num_servers'
                error: @model.get('num_available_servers') < @model.get 'num_servers'
            @

        remove: =>
            @stopListening()
            super()

    # TopBar.DatacentersConnected
    class @TablesAvailable extends Backbone.View
        template: Handlebars.templates['sidebar-tables_available-template']

        initialize: =>
            @listenTo @model, 'change:num_tables', @render
            @listenTo @model, 'change:num_available_tables', @render


        render: =>
            @$el.html @template
                num_tables: @model.get 'num_tables'
                num_available_tables: @model.get 'num_available_tables'
                error: @model.get('num_available_tables') < @model.get 'num_tables'
            @

        remove: =>
            @stopListening()
            super()

    # TopBar.Issues
    # Issue count panel at the top
    class @Issues extends Backbone.View
        className: 'issues'
        template: Handlebars.templates['sidebar-issues-template']

        initialize: =>
            @listenTo @model, 'change:num_issues', @render

        render: =>
            @$el.html @template
                num_issues: @model.get 'num_issues'
            @

        remove: =>
            @stopListening()
            super()

    # TopBar.IssuesBanner
    class @IssuesBanner extends Backbone.View
        template: Handlebars.templates['sidebar-issues_banner-template']
        resolve_issues_route: '#resolve_issues'
        
        events:
            'click .btn-resolve-issues': @toggle_display

        initialize: (data) =>
            @model = data.model
            @collection = data.collection
            @container = data.container

            @show_resolve = true
            @issues_view = []

            @listenTo @model, 'change:num_issues', @render

            @collection.each (issue) =>
                view = new ResolveIssuesView.Issue
                    model: issue
                # The first time, the collection is sorted
                @issues_view.push view
                @$('.issues_list').append view.render().$el

            @collection.on 'add', (index) =>
                view = new ResolveIssuesView.Issue
                    model: issue
                @indexes_view.push view

                position = @collection.indexOf issue
                if @collection.length is 1
                    @$('.issues_list').html view.render().$el
                else if position is 0
                    @$('.issues_list').prepend view.render().$el
                else
                    @$('.issue_container').eq(position-1).after view.render().$el

            @collection.on 'remove', (index) =>
                for view in @indexes_view
                    if view.model is index
                        index.destroy()
                        ((view) ->
                            view.$el.slideUp 'fast', =>
                                view.remove()
                        )(view)
                        break

        toggle_display: =>
            @show_resolve = not @show_resolve
            @container.toggle_display_issues()
            @render()

        render: =>
            @$el.html @template
                num_issues: @model.get 'num_issues'
                no_issues: @model.get('num_issues') is 0
                show_banner: @showing_issues
                show_resolve: @show_resolve
            @

        remove: =>
            @stopListening()
            super()