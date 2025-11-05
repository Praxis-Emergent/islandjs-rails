require 'pathname'

module IslandjsRails
  class Configuration
    attr_accessor :package_json_path, :partials_dir, :supported_cdns,
                  :vendor_script_mode, :vendor_order, :vendor_dir, :combined_basename

    def initialize
      @package_json_path = Rails.root.join('package.json')
      @partials_dir = Rails.root.join('app', 'views', 'shared', 'islands')
      @vendor_script_mode = :external_split  # :external_split or :external_combined
      @vendor_order = %w[react react-dom]    # combine order for :external_combined
      @vendor_dir = Rails.root.join('public', 'vendor', 'islands')
      @combined_basename = 'islands-vendor'
      @supported_cdns = [
        'https://unpkg.com',
        'https://cdn.jsdelivr.net/npm'
      ]
    end


    # Scoped package name mappings
    SCOPED_PACKAGE_MAPPINGS = {
      '@solana/web3.js' => 'solana-web3.js',
      '@babel/core' => 'babel-core',
      '@babel/preset-env' => 'babel-preset-env',
      '@babel/preset-react' => 'babel-preset-react'
    }.freeze
    
    # Maps packages to alternate CDN names (e.g., React 19+ → umd-react).
    def cdn_package_name(package_name, version)
      # Handle nil or empty version strings
      return package_name if version.nil? || version.empty?
      
      # Check if React 19+ to use community-maintained umd-react package
      if ['react', 'react-dom'].include?(package_name)
        major_version = version.split('.').first.to_i rescue 0
        return 'umd-react' if major_version >= 19
      end
      
      package_name
    end

    # Vendor file helper methods
    def vendor_manifest_path
      @vendor_dir.join('manifest.json')
    end

    def vendor_partial_path
      @partials_dir.join('_vendor_umd.html.erb')
    end

    def vendor_file_path(package_name, version)
      safe_name = package_name.gsub(/[@\/]/, '_').gsub(/-/, '_')
      @vendor_dir.join("#{safe_name}-#{version}.min.js")
    end

    def combined_vendor_path(hash)
      @vendor_dir.join("#{@combined_basename}-#{hash}.js")
    end
  end
end
