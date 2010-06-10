dir = "/#{`which #{$PROGRAM_NAME}`.split("/")[0..-2].join("/")}"
Dir.chdir("#{dir}/metrics-history") do
  require 'AnalizoRunner'
end

class MetricsAnalyzer < Qt::Dialog
  slots :analysis, :select_dir, :save_to_file
  slots 'change_where_from(int)'
  signals :analysis_finished
  
  attr_reader :metrics
  
  def initialize(parent = nil)
    super
    @combobox_where_from = Qt::ComboBox.new
    @location_line_edit = Qt::LineEdit.new
    @checkbox_svn = Qt::CheckBox.new "Subversion repository"
    @button_calculate = Qt::PushButton.new "Extract"
    @metricsfor_text = Qt::Label.new "Insert a git directory to extract the metrics from."
    @button_dir = Qt::PushButton.new "Directory..."
    @button_save = Qt::PushButton.new "Save table to file..."
    @metrics_table_view = Qt::TableView.new
    @metrics_table_model = Qt::StandardItemModel.new @metrics_table_view
    @upper_layout = Qt::HBoxLayout.new
    @main_layout = Qt::VBoxLayout.new
    
    @combobox_where_from.insertItems(0, ["From folder", "From URL"])
    @location_line_edit.setText Dir.pwd
    @metrics_table_model.setHorizontalHeaderLabels AnalizoRunner.fields.map{ |f| f[0].to_s }
    @metrics_table_view.setModel @metrics_table_model
    @checkbox_svn.hide
    
    connect @combobox_where_from, SIGNAL('currentIndexChanged(int)'), self, SLOT('change_where_from(int)')
    connect @button_calculate, SIGNAL('clicked()'), self, SLOT('analysis()')
    connect @button_dir, SIGNAL('clicked()'), self, SLOT('select_dir()')
    connect @button_save, SIGNAL('clicked()'), self, SLOT('save_to_file()')
    
    [
      @combobox_where_from,
      @location_line_edit,
      @button_dir,
      @checkbox_svn,
      @button_calculate,
      @button_save
    ].each { |w| @upper_layout.addWidget w }
    @main_layout.addLayout @upper_layout
    @main_layout.addWidget @metricsfor_text
    @main_layout.addWidget @metrics_table_view
    setLayout @main_layout
    resize 800, 480
  end
  def analysis
    if @combobox_where_from.currentIndex == 0
      options = { :folder => @location_line_edit.text, :url => :none }
    elsif @combobox_where_from.currentIndex == 1
      options = { :folder => :none, :url => @location_line_edit.text }
    end
    if @checkbox_svn.isChecked
      options[:version_control] = "svn"
    end
    @location_line_edit.setEnabled(false); @button_calculate.setEnabled(false); @button_dir.setEnabled(false)
    @metrics = AnalizoRunner.metrics_history(options)
    @location_line_edit.setEnabled(true); @button_calculate.setEnabled(true); @button_dir.setEnabled(true)
    @metricsfor_text.setText("Metrics for project #{@metrics[1]}:")
    @metrics[0][0..-2].each_with_index do |metric, row|
      AnalizoRunner.fields.each_with_index do |f, i|
        fi = Qt::StandardItem.new
        fi.setText(metric[f[1]][f[0]].to_s)
        fi.setEditable(false)
        fi.setSelectable(false)
        @metrics_table_model.setItem(row, i, fi)
      end
    end
    emit :analysis_finished
  end
  def select_dir
    @location_line_edit.setText Qt::FileDialog.getExistingDirectory(self, "Select git repository folder...", @location_line_edit.text)
  end
  def save_to_file
    filename = Qt::FileDialog.getSaveFileName(self, "Save metrics to file...", @location_line_edit.text+"/#{time_start_str = Time.now.strftime('%Y%m%d%H%M%S')}-#{@metrics[1]}-metrics.csv", "CSV files (*.csv)")
    if !filename.empty?
      File.open(filename, 'w') do |file|
        file.puts AnalizoRunner.fields.map{ |f| f[0].to_s }.join(',')
        @metrics[0][0..-2].each do |metr|
          file.puts AnalizoRunner.metrics_to_csv_line(metr)
        end
      end
    end
  end
  def change_where_from(where)
    if where == 0
      @button_dir.show
      @checkbox_svn.hide
      @location_line_edit.setText ""
    elsif where == 1
      @button_dir.hide
      @checkbox_svn.show
      @location_line_edit.setText ""
    end
  end
end

