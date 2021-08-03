# -*- coding: utf-8 -*-
require 'sinatra'
require 'slim'
require 'open3'
require 'treetop'

get('/css/styles.css'){ scss :styles }


class Object
  unless Object.instance_methods.include?(:blank?)
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
  end
end

def sdfToYang
  puts "SDF to YANG!"
  if @sdf != ""
    f = File.open("test.sdf.json", 'w')
    f.write(@sdf)
    f.close
    if validateSdf("test.sdf.json").blank?
      `./converter -f test.sdf.json -o result.yang`
      @yang = File.read("result.yang") if File.exist?("result.yang")
      File.delete("result.yang") if File.exist?("result.yang")
    else
      @error = "Invalid input: " + validateSdf("test.sdf.json")
    end
     File.delete("test.sdf.json") if File.exist?("test.sdf.json")
  end
end

def yangToSdf
  puts "YANG to SDF!"
  if @yang != ""
    fname = ""
    if @yang.match(/module ([^\s]*)/)
      fname = @yang[/module ([^\s]*)/,1] + ".yang"
    end
    if fname != ""
      f = File.open(fname, 'w')
      f.write(@yang)
      f.close
      if validateYang(fname).blank?
        `./converter -f #{fname} -o test_out.sdf.json`
        @sdf = File.read("test_out.sdf.json") if File.exist?("test_out.sdf.json")
        File.delete("test_out.sdf.json") if File.exist?("test_out.sdf.json")
      else
        @error = "Invalid input: " + validateYang(fname)
      end
      File.delete(fname) if File.exist?(fname)
    else
      @error = "Invalid input: not a YANG module"
    end
  end
end

def validateYang (path)
  if @yang != ""
    puts "YANG validation"
    stdout, stderr, status = Open3.capture3("pyang #{path}")
    stderr
  end
end

def validateSdf (path)
  if @sdf != ""
    puts "SDF validation"
    stdout, stderr, status = Open3.capture3("jsonschema -i #{path} sdf-validation.cddl")
    # `jsonschema --instance #{path} sdf-validation.cddl`
    stderr
  end
end

def loadSdfExample
  puts 'Loading ' + @sdfexmpl
  @sdf = File.read(@sdfexmpl) if File.exist?(@sdfexmpl)
end

def loadYangExample
  if @yangexmpl != 'choose an example'
    puts 'Loading ' + @yangexmpl
    @yang = File.read(@yangexmpl) if File.exist?(@yangexmpl)
  end
end

get '/' do
  @sdf = params[:sdf]
  @yang = params[:yang]
  if @sdf.blank?
    if !@yang.blank?
      yangToSdf
    end
  else
    if @yang.blank?
      sdfToYang
    end
  end
  slim :index
end

post '/' do
  @sdf = params[:sdf]
  @yang = params[:yang]
  @sdfexmpl = params[:sdfexmpl]
  @yangexmpl = params[:yangexmpl]
  if params[:sdftoyang]
    sdfToYang
  else
    if params[:yangtosdf]
      yangToSdf
    else
      if params[:submitsdfexmpl]
        loadSdfExample
      else
        if params[:submityangexmpl]
          loadYangExample
        end
      end
    end
  end
  slim :index
end

__END__
@@layout
doctype html
html lang="en"
  head
    title== @title || 'SDF YANG converter playground'
    meta charset="utf-8"
    link rel="stylesheet" href="/css/styles.css"
  body
    #right
      | SDF YANG converter playground. 
      a<> href="mailto:sdfyangconverter@gmail.com" Feedback
      | on conversion results is greatly appreciated.<br><br> See
      a<> href="https://www.ietf.org/archive/id/draft-ietf-asdf-sdf-07.html" draft-ietf-asdf-sdf-07
      | for the SDF specification, 
      a<> href="https://tools.ietf.org/html/rfc7950" RFC 7950
      | for the YANG specification,<br>
      a<> href="https://www.ietf.org/archive/id/draft-kiesewalter-asdf-yang-sdf-00.html" draft-kiesewalter-asdf-yang-sdf-00
      | for mapping details.<br><br>Get the converter as a command line tool on
      a<> href="https://github.com/jkiesewalter/sdf-yang-converter" GitHub.
      end
    header role="banner"
      h1.logo
        a href='/' SDF ↔ YANG
    #main.content
      == yield

@@index
- if @error
  p.warning
    == @error
form method="POST"
  table
    tr
      td
         a SDF 
         input.button name="sdftoyang" type="submit" value="Convert to YANG →" accesskey="]" title="Convert to SDF"
      td
         input.button name="yangtosdf" type="submit" value="← Convert to SDF" accesskey="[" title="Convert to YANG"
         a  YANG
         = " "
    tr
      td
        select name="sdfexmpl" type="select" title="Show SDF examples"
          option select an example
          option sdfobject-alarm.sdf.json
          option sdfobject-batterymaterial.sdf.json
        input.button name="submitsdfexmpl" type="submit" value="Load example ↓" title="Submit selection"
      td
        select name="yangexmpl" type="select" title="Show YANG examples"
          option select an example
          option ietf-alarms@2019-09-11.yang
          option ietf-access-control-list@2019-03-04.yang
          option ietf-system@2014-08-06.yang
        input.button name="submityangexmpl" type="submit" value="↓ Load example" title="Submit selection"
    tr
      td
         textarea#sdf name="sdf" placeholder="Enter a SDF model here (must not import from other models)" autofocus="autofocus"
           = @sdf
      td
         textarea#yang name="yang" placeholder="Enter an YANG module here (can only import modules from the YANG GitHub repository)" autofocus="autofocus"
           = @yang


@@styles
$purple:#007fff;
$green:#ff8000;
body{ font: 13pt/1.4 arial, sans-serif; }
header{ overflow: hidden; }
#right{float:right; font: 9pt/1 palatino;}
.logo{float:left;overflow: hidden; }
.logo a{ color: $purple; font: 48pt/1 palatino; text-decoration: none; &:hover{color:$green;}}
.title{ color: $green; font: 32pt/1 palatino; }
.button {text-decoration: none; font-weight: bold; padding: 4px 8px; border-radius: 10px; background: $green; color: white; border:none; &:hover{background:$purple;}}
.warning {color: #ff8000;}
header .button{ float:left; margin: 36px 10px 0;}
form label {display: block;}
form select {display: block;}
td {width: 45%;}
table {width: 100%; }
textarea {width: 100%;}
textarea {min-height: 600px; }
