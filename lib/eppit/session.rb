require 'eppit/version'

# Gem and other dependencies
require 'rexml/document'
require 'nokogiri'
require 'net/http'
require 'curb'
require 'uri'
require 'uuidtools'
require 'require_parameters'

require 'eppit/domain'
require 'eppit/contact'
require 'eppit/exceptions'
require 'eppit/xml_interface'

module Eppit #:nodoc:
  class Response
    attr_accessor :msg
    attr_accessor :object
    attr_accessor :http_response

    def initialize(http_response)
      @http_response = http_response
      @msg = Eppit::Message.from_xml(http_response.body)
      @object = nil
    end
  end

  class Session
    include RequiresParameters

    attr_accessor :uri, :lang, :extensions, :version
    attr_accessor :ns

    attr_reader :logger
    attr_reader :status
    attr_reader :cookies

    # ==== Required Attrbiutes
    #
    # * <tt>:uri</tt> - The EPP server's URI
    # * <tt>:tag</tt> - The tag or username used with <tt><login></tt> requests.
    # * <tt>:password</tt> - The password used with <tt><login></tt> requests.
    #
    # ==== Optional Attributes
    #
    # * <tt>:lang</tt> - Set custom language attribute. Default is 'en'.
    # * <tt>:services</tt> - Use custom EPP services in the <login> frame. The defaults use the EPP standard domain, contact and host 1.0 services.
    # * <tt>:extensions</tt> - URLs to custom extensions to standard EPP. Use these to extend the standard EPP (e.g., Nominet uses extensions). Defaults to none.
    # * <tt>:version</tt> - Set the EPP version. Defaults to "1.0".
    # * <tt>:logger</tt> - Logger compatible object to which to log events
    # * <tt>:store_file</tt> - Filename in which to store cookies and session state
    # * <tt>:xml_log_file</tt> - Filename in which to save XML maessages
    # * <tt>:clid_prefix</tt> - Prefix used to generate client transaction ID
    # * <tt>:session_handling</tt> - Session handling method: :auto, :manual, :disable
    # * <tt>:silence_empty_polls</tt> - Silence Empty Pools, avoids logging poll commands resulting in "no message in queue"
    #
    def initialize(attributes = {})
      requires!(attributes, :uri, :tag, :password)

      @uri        = URI.parse(attributes[:uri]).normalize
      @tag        = attributes[:tag]
      @password   = attributes[:password]
      @lang       = attributes[:lang]       || 'en'
      @services   = attributes[:services]   || ['urn:ietf:params:xml:ns:domain-1.0',
                                                'urn:ietf:params:xml:ns:contact-1.0',
                                                'urn:ietf:params:xml:ns:host-1.0']
      @extensions = attributes[:extensions] || []
      @version    = attributes[:version]    || '1.0'
      @logger     = attributes[:logger]
      @store_file   = attributes[:store_file]
      @xml_log_file = attributes[:xml_log_file]
      @clid_prefix = attributes[:clid_prefix] || (@tag + '-')
      @session_handling = attributes[:session_handling] || :auto
      @silence_empty_polls = attributes[:silence_empty_polls] || false
      @debug_http = attributes[:debug_http] || false

      @xml_log_buffer = nil

      @ns = { 'xmlns' => 'urn:ietf:params:xml:ns:epp-1.0',
              'domain' => 'urn:ietf:params:xml:ns:domain-1.0',
              'rgp' => 'urn:ietf:params:xml:ns:rgp-1.0',
              'extepp' => 'http://www.nic.it/ITNIC-EPP/extepp-2.0',
              'extdom' => 'http://www.nic.it/ITNIC-EPP/extdom-2.0' }

      @http = Net::HTTP.new(@uri.host, @uri.port)
      if @uri.scheme == 'https'
        @http.use_ssl = true
        @http.ca_file = attributes[:ca_file] || '/etc/ssl/certs/ca-certificates.crt'
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      @http.set_debug_output($stderr) if @debug_http

      @status = :unknown

      load_store
    end

    def intercept_xml_log
      @xml_log_buffer = ''

      begin
        yield
      ensure
        buf = @xml_log_buffer
        @xml_log_buffer = nil
      end

      buf
    end

    def contact_check(contacts)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.check = Eppit::Message::Command::Check.new do |check|
            check.contact_check = Eppit::Message::Command::Check::ContactCheck.new do |contact_check|
              contact_check.ids = contacts
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = {}
      resp.msg.response.res_data.contact_chk_data.cds.each do |x|
        resp.object[x.id] = { avail: x.avail }
      end

      resp
    end

    def contact_info(contact_id, opts = {})
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.info = Eppit::Message::Command::Info.new do |info|
            info.contact_info = Eppit::Message::Command::Info::ContactInfo.new do |contact_info|
              contact_info.id = contact_id

              if opts[:auth_info_pw]
                contact_info.auth_info = Eppit::Message::ContactAuthInfo.new do |auth_info|
                  auth_info.pw = opts[:auth_info_pw]
                end
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = Contact.new(
        nic_id: resp.msg.response.res_data.contact_inf_data.id,
        roid: resp.msg.response.res_data.contact_inf_data.roid,
        statuses: resp.msg.response.res_data.contact_inf_data.statuses.map(&:s),
        name: resp.msg.response.res_data.contact_inf_data.postal_info.name,
        org: resp.msg.response.res_data.contact_inf_data.postal_info.org,
        street: resp.msg.response.res_data.contact_inf_data.postal_info.addr.street,
        city: resp.msg.response.res_data.contact_inf_data.postal_info.addr.city,
        sp: resp.msg.response.res_data.contact_inf_data.postal_info.addr.sp,
        pc: resp.msg.response.res_data.contact_inf_data.postal_info.addr.pc,
        cc: resp.msg.response.res_data.contact_inf_data.postal_info.addr.cc,
        voice: resp.msg.response.res_data.contact_inf_data.voice,
        fax: resp.msg.response.res_data.contact_inf_data.fax,
        email: resp.msg.response.res_data.contact_inf_data.email,
        #        :auth_info_pw => resp.msg.response.res_data.contact_inf_data.
        cl_id: resp.msg.response.res_data.contact_inf_data.cl_id,
        cr_id: resp.msg.response.res_data.contact_inf_data.cr_id,
        cr_date: resp.msg.response.res_data.contact_inf_data.cr_date,
        up_id: resp.msg.response.res_data.contact_inf_data.up_id,
        up_date: resp.msg.response.res_data.contact_inf_data.up_date,
        consent_for_publishing: resp.msg.response.extension ?
                                   resp.msg.response.extension.extcon_inf_data.consent_for_publishing : nil,
        registrant_nationality_code: resp.msg.response.extension.extcon_inf_data.registrant ?
                                        resp.msg.response.extension.extcon_inf_data.registrant.nationality_code : nil,
        registrant_entity_type: resp.msg.response.extension.extcon_inf_data.registrant ?
                                   resp.msg.response.extension.extcon_inf_data.registrant.entity_type : nil,
        registrant_reg_code: resp.msg.response.extension.extcon_inf_data.registrant ?
                                resp.msg.response.extension.extcon_inf_data.registrant.reg_code : nil
      )

      resp
    end

    def contact_create(contact)
      contact = Contact.new(contact) if contact.is_a?(Hash)

      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.create = Eppit::Message::Command::Create.new do |create|
            create.contact_create = Eppit::Message::Command::Create::ContactCreate.new do |contact_create|
              contact_create.id = contact.nic_id
              contact_create.postal_info = Eppit::Message::Command::Create::ContactCreate::PostalInfo.new do |postal_info|
                postal_info.type = 'loc'
                postal_info.name = contact.name
                postal_info.org = contact.org

                postal_info.addr = Eppit::Message::Command::Create::ContactCreate::PostalInfo::Addr.new do |addr|
                  addr.street = contact.street
                  addr.city = contact.city
                  addr.sp = contact.sp
                  addr.pc = contact.pc
                  addr.cc = contact.cc
                end
              end

              contact_create.voice = contact.voice
              contact_create.voice_x = ''
              contact_create.fax = contact.fax
              contact_create.email = contact.email
              contact_create.auth_info = Eppit::Message::ContactAuthInfo.new do |auth_info|
                auth_info.pw = 'NOTUSED' # contact.auth_info_pw
              end
            end
          end

          command.extension = Eppit::Message::Command::Extension.new do |extension|
            extension.extcon_create = Eppit::Message::Command::Extension::ExtconCreate.new do |extcon_create|
              extcon_create.consent_for_publishing = contact.consent_for_publishing

              if contact.registrant_entity_type
                extcon_create.registrant = Eppit::Message::Command::Extension::ExtconCreate::Registrant.new do |registrant|
                  registrant.nationality_code = contact.registrant_nationality_code
                  registrant.entity_type = contact.registrant_entity_type
                  registrant.reg_code = contact.registrant_reg_code
                end
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = { id: resp.msg.response.res_data.contact_cre_data.id,
                      cr_date: resp.msg.response.res_data.contact_cre_data.cr_date }

      resp
    end

    def contact_update_with_old(old_contact, new_contact)
      contact_update(old_contact.nic_id, Contact::Diff.new(old_contact, new_contact))
    end

    def contact_update(nic_id, diff)
      diff = Contact::Diff.new(diff) unless diff.is_a?(Contact::Diff)

      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.update = Eppit::Message::Command::Update.new do |update|
            update.contact_update = Eppit::Message::Command::Update::ContactUpdate.new do |contact_update|
              contact_update.id = nic_id

              # Add
              contact_update.add = Eppit::Message::Command::Update::ContactUpdate::Add.new do |add|
                add.statuses = diff.add ? diff.add.statuses.map do |x|
                  Eppit::Message::Command::Update::ContactUpdate::Status.new do |status|
                    status.s = x
                    status.lang = 'en'
                  end
                end : nil
              end
              contact_update.add = nil if contact_update.add.to_xml.children.empty?

              # Chg
              contact_update.chg = Eppit::Message::Command::Update::ContactUpdate::Chg.new do |chg|
                chg.postal_info = Eppit::Message::Command::Update::ContactUpdate::Chg::PostalInfo.new do |postal_info|
                  postal_info.type = 'loc'
                  postal_info.name = diff.chg.name
                  postal_info.org = diff.chg.org

                  postal_info.addr = Eppit::Message::Command::Update::ContactUpdate::Chg::PostalInfo::Addr.new do |addr|
                    addr.street = diff.chg.street
                    addr.city = diff.chg.city
                    addr.sp = diff.chg.sp
                    addr.pc = diff.chg.pc
                    addr.cc = diff.chg.cc
                  end
                  postal_info.addr = nil if postal_info.addr.to_xml.children.empty?
                end
                chg.postal_info = nil if chg.postal_info.to_xml.children.empty?

                chg.voice = diff.chg.voice
                #                contact_update.voice_x = ''
                chg.fax = diff.chg.fax
                chg.email = diff.chg.email
              end
              contact_update.chg = nil if contact_update.chg.to_xml.children.empty?

              # Rem
              contact_update.rem = Eppit::Message::Command::Update::ContactUpdate::Rem.new do |rem|
                rem.statuses = diff.rem ? diff.rem.statuses.map do |x|
                  Eppit::Message::Command::Update::ContactUpdate::Status.new do |status|
                    status.s = x
                    status.lang = 'en'
                  end
                end : nil
              end
              contact_update.rem = nil if contact_update.rem.to_xml.children.empty?
            end
          end

          if diff.chg.consent_for_publishing ||
             diff.chg.registrant_entity_type ||
             diff.chg.registrant_nationality_code ||
             diff.chg.registrant_reg_code
            command.extension = Eppit::Message::Command::Extension.new do |extension|
              extension.extcon_update = Eppit::Message::Command::Extension::ExtconUpdate.new do |extcon_update|
                extcon_update.consent_for_publishing = diff.chg.consent_for_publishing

                if diff.chg.registrant_entity_type ||
                   diff.chg.registrant_nationality_code ||
                   diff.chg.registrant_reg_code
                  extcon_update.registrant = Eppit::Message::Command::Extension::ExtconUpdate::Registrant.new do |registrant|
                    registrant.nationality_code = diff.chg.registrant_nationality_code
                    registrant.entity_type = diff.chg.registrant_entity_type
                    registrant.reg_code = diff.chg.registrant_reg_code
                  end
                end
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp
    end

    def contact_delete(contact_id)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.delete = Eppit::Message::Command::Delete.new do |delete|
            delete.contact_delete = Eppit::Message::Command::Delete::ContactDelete.new do |contact_delete|
              contact_delete.id = contact_id
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp
    end

    def domain_check(domains)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.check = Eppit::Message::Command::Check.new do |check|
            check.domain_check = Eppit::Message::Command::Check::DomainCheck.new do |domain_check|
              domain_check.names = domains
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = {}
      resp.msg.response.res_data.domain_chk_data.cds.each do |x|
        resp.object[x.name] = { avail: x.avail, reason: x.reasons['en'] }
      end

      resp
    end

    def domain_info(domain_name, opts = {})
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.info = Eppit::Message::Command::Info.new do |info|
            info.domain_info = Eppit::Message::Command::Info::DomainInfo.new do |domain_info|
              domain_info.name = domain_name
              domain_info.hosts = 'all'

              if opts[:auth_info_pw]
                domain_info.auth_info = Eppit::Message::DomainAuthInfo.new do |auth_info|
                  auth_info.pw = opts[:auth_info_pw]
                end
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      epp_resp = resp.msg

      domain = Domain.new(
        name: epp_resp.response.res_data.domain_inf_data.name,
        roid: epp_resp.response.res_data.domain_inf_data.roid,

        statuses: epp_resp.response.res_data.domain_inf_data.statuses.map { |x| "domain:#{x.status}" },

        registrant: epp_resp.response.res_data.domain_inf_data.registrant,

        admin_contacts: epp_resp.response.res_data.domain_inf_data.contacts.select { |x| x.type == 'admin' }.map(&:id),
        tech_contacts: epp_resp.response.res_data.domain_inf_data.contacts.select { |x| x.type == 'tech' }.map(&:id),

        nameservers: epp_resp.response.res_data.domain_inf_data.ns.map do |x|
          Domain::Nameserver.new(
            name: x.host_name,
            ipv4: x.host_addr.select { |host_addr| host_addr.type == 'v4' }
                                 .map(&:address),
            ipv6: x.host_addr.select { |host_addr| host_addr.type == 'v6' }
                                 .map(&:address)
          )
        end,

        cl_id: epp_resp.response.res_data.domain_inf_data.cl_id,
        cr_id: epp_resp.response.res_data.domain_inf_data.cr_id,
        cr_date: epp_resp.response.res_data.domain_inf_data.cr_date,
        ex_date: epp_resp.response.res_data.domain_inf_data.ex_date,
        up_id: epp_resp.response.res_data.domain_inf_data.up_id,
        up_date: epp_resp.response.res_data.domain_inf_data.up_date,
        tr_date: epp_resp.response.res_data.domain_inf_data.tr_date,
        auth_info_pw: epp_resp.response.res_data.domain_inf_data.auth_info.pw
      )

      if epp_resp.response.extension
        if epp_resp.response.extension.rgp_inf_data
          domain.statuses += epp_resp.response.extension.rgp_inf_data.rgp_status.map { |x| "rgp:#{x.s}" }
        end

        if epp_resp.response.extension.extdom_inf_data
          domain.statuses += epp_resp.response.extension.extdom_inf_data.own_statuses.map { |x| "extdom:#{x.s}" }
        end

        if epp_resp.response.extension.inf_ns_to_validate_data
          domain.nameservers_to_validate = epp_resp.response.extension.inf_ns_to_validate_data.ns_to_validate.map { |x|
            Domain::Nameserver.new(
              name: x.host_name,
              ipv4: x.host_addr.select { |host_addr| host_addr.type == 'v4' }
                                   .map(&:address),
              ipv6: x.host_addr.select { |host_addr| host_addr.type == 'v6' }
                                   .map(&:address)
            )
          }
        end
      end

      resp.object = domain

      resp
    end

    def domain_create(domain)
      domain = Domain.new(domain) unless domain.is_a?(Domain)

      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.create = Eppit::Message::Command::Create.new do |create|
            create.domain_create = Eppit::Message::Command::Create::DomainCreate.new do |domain_create|
              domain_create.name = domain.name
              domain_create.period = domain.period

              domain_create.ns = domain.nameservers.map { |ns|
                Eppit::Message::HostAttr.new do |host_attr|
                  host_attr.host_name = ns.name
                  host_attr.host_addr = []

                  if ns.ipv4
                    ipv4s = ns.ipv4.is_a?(Array) ? ns.ipv4 : [ns.ipv4]
                    host_attr.host_addr += ipv4s.map do |addr|
                      Eppit::Message::HostAttr::HostAddr.new do |host_addr|
                        host_addr.type = 'v4'
                        host_addr.address = addr
                      end
                    end
                  end

                  if ns.ipv6
                    ipv6s = ns.ipv6.is_a?(Array) ? ns.ipv6 : [ns.ipv6]
                    host_attr.host_addr += ipv6s.map do |addr|
                      Eppit::Message::HostAttr::HostAddr.new do |host_addr|
                        host_addr.type = 'v6'
                        host_addr.address = addr
                      end
                    end
                 end
                end
              }

              domain_create.registrant = domain.registrant

              domain_create.contacts = domain.admin_contacts.map { |c|
                Eppit::Message::Contact.new do |contact|
                  contact.type = 'admin'
                  contact.id = c
                end
              } + domain.tech_contacts.map do |c|
                Eppit::Message::Contact.new do |contact|
                  contact.type = 'tech'
                  contact.id = c
                end
              end

              domain_create.auth_info = Eppit::Message::DomainAuthInfo.new do |auth_info|
                auth_info.pw = domain.auth_info_pw
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = { name: resp.msg.response.res_data.domain_cre_data.name,
                      cr_date: resp.msg.response.res_data.domain_cre_data.cr_date,
                      ex_date: resp.msg.response.res_data.domain_cre_data.ex_date }

      resp
    end

    def domain_update_with_old(old_domain, new_domain)
      domain_update(old_domain.name, Domain::Diff.new(old_domain, new_domain))
    end

    def domain_update(domain_name, diff)
      diff = Domain::Diff.new(diff) unless diff.is_a?(Domain::Diff)

      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.update = Eppit::Message::Command::Update.new do |update|
            update.domain_update = Eppit::Message::Command::Update::DomainUpdate.new do |domain_update|
              domain_update.name = domain_name

              # Add
              if diff.add

                diff.add.admin_contacts ||= []
                diff.add.tech_contacts ||= []
                diff.add.statuses ||= []
                diff.add.nameservers ||= []

                domain_update.add = Eppit::Message::Command::Update::DomainUpdate::Add.new do |add|
                  add.contacts = diff.add.admin_contacts.map { |c|
                    Eppit::Message::Contact.new do |contact|
                      contact.type = 'admin'
                      contact.id = c
                    end
                  } + diff.add.tech_contacts.map do |c|
                    Eppit::Message::Contact.new do |contact|
                      contact.type = 'tech'
                      contact.id = c
                    end
                  end

                  add.statuses = diff.add.statuses.map { |x|
                    Eppit::Message::Command::Update::DomainUpdate::Status.new do |status|
                      status.s = x
                      status.lang = 'en'
                    end
                  }
                  add.statuses = nil if add.statuses.empty?

                  add.ns = diff.add.nameservers.map { |ns|
                    ns = Domain::Nameserver.new(ns) unless ns.is_a?(Domain::Nameserver)

                    Eppit::Message::HostAttr.new do |host_attr|
                      host_attr.host_name = ns.name
                      host_attr.host_addr = []

                      if ns.ipv4
                        ipv4s = ns.ipv4.is_a?(Array) ? ns.ipv4 : [ns.ipv4]
                        host_attr.host_addr += ipv4s.map do |addr|
                          Eppit::Message::HostAttr::HostAddr.new do |host_addr|
                            host_addr.type = 'v4'
                            host_addr.address = addr
                          end
                        end
                      end

                      if ns.ipv6
                        ipv6s = ns.ipv6.is_a?(Array) ? ns.ipv6 : [ns.ipv6]
                        host_attr.host_addr += ipv6s.map do |addr|
                          Eppit::Message::HostAttr::HostAddr.new do |host_addr|
                            host_addr.type = 'v6'
                            host_addr.address = addr
                          end
                        end
                      end
                    end
                  }
                  add.ns = nil if add.ns.empty?
                end
                domain_update.add = nil if domain_update.add.to_xml.children.empty?
              end

              # Chg
              if diff.chg
                domain_update.chg = Eppit::Message::Command::Update::DomainUpdate::Chg.new do |chg|
                  chg.registrant = diff.chg.registrant

                  if diff.chg.auth_info_pw
                    chg.auth_info = Eppit::Message::DomainAuthInfo.new do |auth_info|
                      auth_info.pw = diff.chg.auth_info_pw
                    end
                  end
                end
                domain_update.chg = nil if domain_update.chg.to_xml.children.empty?
              end

              # Rem
              if diff.rem

                diff.rem.admin_contacts ||= []
                diff.rem.tech_contacts ||= []
                diff.rem.statuses ||= []
                diff.rem.nameservers ||= []

                domain_update.rem =  Eppit::Message::Command::Update::DomainUpdate::Rem.new do |rem|
                  rem.contacts = diff.rem.admin_contacts.map { |c|
                    Eppit::Message::Contact.new do |contact|
                      contact.type = 'admin'
                      contact.id = c
                    end
                  } + diff.rem.tech_contacts.map do |c|
                        Eppit::Message::Contact.new do |contact|
                          contact.type = 'tech'
                          contact.id = c
                        end
                      end
                  rem.contacts = nil if rem.contacts.empty?

                  rem.statuses = diff.rem.statuses.map { |x|
                    Eppit::Message::Command::Update::DomainUpdate::Status.new do |status|
                      status.s = x
                      status.lang = 'en'
                    end
                  }
                  rem.statuses = nil if rem.statuses.empty?

                  rem.ns = diff.rem.nameservers.map { |ns|
                    ns = Domain::Nameserver.new(ns) unless ns.is_a?(Domain::Nameserver)

                    Eppit::Message::HostAttr.new do |host_attr|
                      host_attr.host_name = ns.name
                      host_attr.host_addr = []

                      if ns.ipv4
                        ipv4s = ns.ipv4.is_a?(Array) ? ns.ipv4 : [ns.ipv4]
                        host_attr.host_addr = ipv4s.map { |addr|
                          Eppit::Message::HostAttr::HostAddr.new do |host_addr|
                            host_addr.type = 'v4'
                            host_addr.address = addr
                          end
                        }
                      end

                      if ns.ipv6
                        ipv6s = ns.ipv6.is_a?(Array) ? ns.ipv6 : [ns.ipv6]
                        host_attr.host_addr += ipv6s.map do |addr|
                          Eppit::Message::HostAttr::HostAddr.new do |host_addr|
                            host_addr.type = 'v6'
                            host_addr.address = addr
                          end
                        end
                      end
                    end
                  }
                  rem.ns = nil if rem.ns.empty?
                end
                domain_update.rem = nil if domain_update.rem.to_xml.children.empty?
              end
            end
          end

          #          if diff.chg.consent_for_publishing
          #            command.extension = Eppit::Message::Command::Extension.new do |extension|
          #              extension.extcon_update = Eppit::Message::Command::Extension::ExtconUpdate.new do |extcon_update|
          #                extcon_update.consent_for_publishing = domain.consent_for_publishing
          #
          #                if domain.registrant_entity_type
          #                  extcon_update.registrant =  Eppit::Message::Command::Extension::ExtconUpdate::Registrant.new do |registrant|
          #                    registrant.nationality_code = domain.registrant_nationality_code
          #                    registrant.entity_type = domain.registrant_entity_type
          #                    registrant.reg_code = domain.registrant_reg_code
          #                  end
          #                end
          #              end
          #            end
          #          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp
    end

    def domain_delete(domain_name)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.delete = Eppit::Message::Command::Delete.new do |delete|
            delete.domain_delete = Eppit::Message::Command::Delete::DomainDelete.new do |domain_delete|
              domain_delete.name = domain_name
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp
    end

    def domain_undelete(domain_name)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.update = Eppit::Message::Command::Update.new do |update|
            update.domain_update = Eppit::Message::Command::Update::DomainUpdate.new do |domain_update|
              domain_update.name = domain_name

              domain_update.chg =  Eppit::Message::Command::Update::DomainUpdate::Chg.new
            end
          end

          command.extension = Eppit::Message::Command::Extension.new do |extension|
            extension.rgp_update = Eppit::Message::Command::Extension::RgpUpdate.new do |rgp_update|
              rgp_update.restore_op = 'request'
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp
    end

    def domain_transfer_query(domain_name, auth_pw)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.transfer = Eppit::Message::Command::Transfer.new do |transfer|
            transfer.op = 'query'

            transfer.domain_transfer = Eppit::Message::Command::Transfer::DomainTransfer.new do |domain_transfer|
              domain_transfer.name = domain_name
              domain_transfer.auth_info = Eppit::Message::DomainAuthInfo.new do |auth_info|
                auth_info.pw = auth_pw
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = {
        tr_status: resp.msg.response.res_data.domain_trn_data.tr_status,
        re_id: resp.msg.response.res_data.domain_trn_data.re_id,
        re_date: resp.msg.response.res_data.domain_trn_data.re_date,
        ac_id: resp.msg.response.res_data.domain_trn_data.ac_id,
        ac_date: resp.msg.response.res_data.domain_trn_data.ac_date
      }

      resp
    end

    def domain_transfer_request(domain_name, auth_pw, trade = {})
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.transfer = Eppit::Message::Command::Transfer.new do |transfer|
            transfer.op = 'request'

            transfer.domain_transfer = Eppit::Message::Command::Transfer::DomainTransfer.new do |domain_transfer|
              domain_transfer.name = domain_name
              domain_transfer.auth_info = Eppit::Message::DomainAuthInfo.new do |auth_info|
                auth_info.pw = auth_pw
              end
            end
          end

          unless trade.empty?
            command.extension = Eppit::Message::Command::Extension.new do |extension|
              extension.extdom_trade = Eppit::Message::Command::Extension::ExtdomTrade.new do |extdom_trade|
                extdom_trade.new_registrant = trade[:new_registrant]
                extdom_trade.new_auth_info = Eppit::Message::Command::Extension::ExtdomTrade::NewAuthInfo.new do |auth_info|
                  auth_info.pw = trade[:new_auth_info_pw]
                end
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = {
        tr_status: resp.msg.response.res_data.domain_trn_data.tr_status,
        re_id: resp.msg.response.res_data.domain_trn_data.re_id,
        re_date: resp.msg.response.res_data.domain_trn_data.re_date,
        ac_id: resp.msg.response.res_data.domain_trn_data.ac_id,
        ac_date: resp.msg.response.res_data.domain_trn_data.ac_date
      }

      resp
    end

    def domain_transfer_cancel(domain_name, auth_pw)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.transfer = Eppit::Message::Command::Transfer.new do |transfer|
            transfer.op = 'cancel'

            transfer.domain_transfer = Eppit::Message::Command::Transfer::DomainTransfer.new do |domain_transfer|
              domain_transfer.name = domain_name
              domain_transfer.auth_info = Eppit::Message::DomainAuthInfo.new do |auth_info|
                auth_info.pw = auth_pw
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = {
        tr_status: resp.msg.response.res_data.domain_trn_data.tr_status,
        re_id: resp.msg.response.res_data.domain_trn_data.re_id,
        re_date: resp.msg.response.res_data.domain_trn_data.re_date,
        ac_id: resp.msg.response.res_data.domain_trn_data.ac_id,
        ac_date: resp.msg.response.res_data.domain_trn_data.ac_date
      }

      resp
    end

    def domain_transfer_approve(domain_name, opts = {})
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.transfer = Eppit::Message::Command::Transfer.new do |transfer|
            transfer.op = 'approve'

            transfer.domain_transfer = Eppit::Message::Command::Transfer::DomainTransfer.new do |domain_transfer|
              domain_transfer.name = domain_name

              if opts[:auth_info_pw]
                domain_transfer.auth_info = Eppit::Message::DomainAuthInfo.new do |auth_info|
                  auth_info.pw = opts[:auth_info_pw]
                end
              end
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = {
        tr_status: resp.msg.response.res_data.domain_trn_data.tr_status,
        re_id: resp.msg.response.res_data.domain_trn_data.re_id,
        re_date: resp.msg.response.res_data.domain_trn_data.re_date,
        ac_id: resp.msg.response.res_data.domain_trn_data.ac_id,
        ac_date: resp.msg.response.res_data.domain_trn_data.ac_date
      }

      resp
    end

    def domain_transfer_reject(domain_name)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.transfer = Eppit::Message::Command::Transfer.new do |transfer|
            transfer.op = 'reject'

            transfer.domain_transfer = Eppit::Message::Command::Transfer::DomainTransfer.new do |domain_transfer|
              domain_transfer.name = domain_name
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp.object = {
        tr_status: resp.msg.response.res_data.domain_trn_data.tr_status,
        re_id: resp.msg.response.res_data.domain_trn_data.re_id,
        re_date: resp.msg.response.res_data.domain_trn_data.re_date,
        ac_id: resp.msg.response.res_data.domain_trn_data.ac_id,
        ac_date: resp.msg.response.res_data.domain_trn_data.ac_date
      }

      resp
    end

    def poll(opts = {})
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.poll = Eppit::Message::Command::Poll.new do |poll|
            poll.op = 'req'
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      if @silence_empty_polls || opts[:silence_empty]
        resp = nil
        xml_log = intercept_xml_log do
          begin
            resp = send_request(req)
          rescue
            # Output log especially in case of exception
            File.open(@xml_log_file, 'ab') { |f| f << @xml_log_buffer }
            raise
          end
        end

        if resp.msg.response.msgq
          File.open(@xml_log_file, 'ab') { |f| f << xml_log }
        end
      else
        resp = send_request(req)
      end

      resp
    end

    def ack(message_id)
      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.poll = Eppit::Message::Command::Poll.new do |poll|
            poll.op = 'ack'
            poll.msg_id = message_id
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      resp = send_request(req)

      resp
    end

    #    private

    def hello
      if @session_handling == :auto
        return nil if @status == :helloed
      end

      req = Eppit::Message.new do |epp|
        epp.hello = Eppit::Message::Hello.new
      end

      begin
        resp = send_request_raw(req)
      rescue EOFError, Errno::EPIPE
        disconnect
        connect
        retry
      end

      @status = :helloed
      save_store

      resp
    end

    # Sends a standard login request to the EPP server.
    def login(options = {})
      if @session_handling == :auto
        return nil if @status == :logged_in
        hello if @status == :new
      elsif @session_handling == :manual
        raise "Login in state #{@status} is unexpected"
      end

      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.login = Eppit::Message::Command::Login.new do |login|
            login.cl_id = @tag
            login.pw = @password

            login.new_pw = options[:newpw] if options[:newpw]

            login.options = Eppit::Message::Command::Login::Options.new do |opts|
              opts.version = @version
              opts.lang = @lang
            end

            login.svcs = Eppit::Message::Command::Login::Svcs.new do |svcs|
              svcs.obj_uris = @services
              svcs.ext_uris = @extensions
            end
          end

          command.cl_tr_id = generate_client_transaction_id
        end
      end

      # Receive the login response
      begin
        resp = send_request_raw(req)
      rescue EOFError
        disconnect
        connect
        retry
      end

      if resp.msg.response.result.code == 2002 && resp.msg.response.result.ext_value.reason_code == 4014
        @status = :logged_in
        save_store
      elsif resp.msg.response.result.code >= 2000
        raise Eppit::Session::ErrorResponse, resp.msg
      else
        # command successful, remember new password for this session
        @password = options[:newpw] if options[:newpw]

        @status = :logged_in
        save_store
      end

      resp
    end

    # Sends a standard logout request to the EPP server.
    def logout
      if @session_handling == :auto
        return nil if @status == :helloed
      elsif @session_handling == :manual
        raise "Logout not valid in state #{@status}" if @status != :logged_in
      end

      req = Eppit::Message.new do |epp|
        epp.command = Eppit::Message::Command.new do |command|
          command.logout = Eppit::Message::Command::Logout.new
          command.cl_tr_id = generate_client_transaction_id
        end
      end

      begin
        resp = send_request_raw(req)
      rescue EOFError
        disconnect
        connect
        retry
      end

      @status = :helloed
      save_store

      if resp.msg.response.result.code >= 2000
        raise Eppit::Session::ErrorResponse, resp.msg
      end

      resp
    end

    def send_request_raw(req)
      if req.is_a?(Eppit::Message)
        # Incapsulate it in a Nokogiri document
        req2 = Nokogiri::XML::Document.new
        req2.encoding = 'UTF-8'
        req2.root = req.to_xml
        req = req2
      end

      log_xml_message(req.to_s, 'out', @cookies)

      post = Net::HTTP::Post.new(@uri.path, 'User-Agent' => 'Yggdra EPP Gateway/1.0')
      @cookies.each do |cookie|
        post.add_field('Cookie', cookie)
      end

      post.body = req.to_s

      http_response = @http.request(post)

      log_xml_message(http_response.body, 'in', @cookies)

      if http_response['Set-Cookie']
        new_cookies = http_response.get_fields('Set-Cookie')

        # FIXME: check the proper cookie
        if new_cookies[0] != @cookies[0]
          @cookies = new_cookies
          @status = :new
          save_store
        end
      end

      Response.new(http_response)
    end

    # Sends an XML request to the EPP server, and receives an XML response.
    # <tt><login></tt> and <tt><logout></tt> requests are also wrapped
    # around the request, so we can close the socket immediately after
    # the request is made.
    def send_request(req, _args = {})
      yet_retried = false

      begin
        if @session_handling == :auto
          hello if @status == :new

          login if @status == :helloed
        elsif @session_handling == :manual
          raise "send_request not valid in state #{@status}" if @status != :logged_in
        end

        resp = send_request_raw(req)

        if resp.msg.response.result.code >= 2000
          raise Eppit::Session::ErrorResponse, resp.msg
        end
      rescue EOFError, Errno::EPIPE
        disconnect
        connect
        retry
      rescue Eppit::Session::ErrorResponse => e
        if e.response_code == 2002 && e.reason_code == 4015
          @status = :new
          save_store

          unless yet_retried
            yet_retried = true
            retry
          end
        end

        raise
      end

      resp
    end

    def connect
      @http.start
    end

    # Closes the connection to the EPP server.
    def disconnect
      @http.finish
    end

    private

    def save_store
      store = { cookies: @cookies,
                status: @status }

      File.open(@store_file, 'w') do |f|
        f.write(Marshal.dump(store))
      end
    end

    def load_store
      File.open(@store_file, 'r') do |f|
        store = Marshal.restore(f.read)
        @cookies = store[:cookies]
        @status = store[:status]
      end
    rescue Errno::ENOENT
      @cookies = []
      @status = :new
    end

    def log_xml_message(msg, direction, sid)
      m = ''
      m << "\n<!-- #{Time.now} #{direction.upcase} #{sid} ==================== -->\n"
      m << msg
      m << "\n<!-- END -->\n"

      if @xml_log_buffer
        @xml_log_buffer << m
      elsif @xml_log_file
        File.open(@xml_log_file, 'ab') { |f| f << m }
      end
    end

    def generate_client_transaction_id
      @clid_prefix + UUIDTools::UUID.random_create.to_s
    end
  end
end
