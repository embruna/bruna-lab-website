# Need to do one of these for books, code, etcx.
# description -------------------------------------------------------------

# Export as Better BibTex

# Code for converting exported bibtex file into format that:
# 1) is read into Academic and 2) the pdfs are renamed after being copied
# into the relevant folder
# TODO: not all abstracts being read (may be that some are called "summary")
# TODO: "strings cannot contain newlines" error in some abstracts
# TODO: is there a way to automate the copy paste of files into folder?

# http://www.pik-potsdam.de/~pichler/blog/post/set-this-up/setting-up-this-site/

#' @title bibtex_2academic
#' @description import publications from a bibtex file to a hugo-academic website
#' @author Lorenzo Busetto, phD (2017) <lbusett@gmail.com>
#' @modified Peter Paul Pichler (2019) <pichler@pik-potsdam.de>


# load libraries  ---------------------------------------------------------

library(RefManageR)
library(tidyverse)
library(anytime)
library(tibble)
library(bib2df)
library(janitor)



# select destination folder -----------------------------------------------


# Identify the folder in which publications are kept
outfold <- "./publications/articles"

abstract <- TRUE
overwrite <- TRUE
# load data ---------------------------------------------------------------


# read bibtex -------------------------------------------------------------
# Read in the file
bibfile1 <- "./publications/better_bibtex/EMB_publications/EMB_publications.bib"

# Import the bibtex file and convert to data.frame
mypubs1 <- ReadBib(bibfile1, check = "warn", .Encoding = "UTF-8") %>%
  as.data.frame() %>%
  mutate_all(funs(str_remove_all(., "[{}\"]"))) %>%
  mutate_all(funs(str_replace_all(., "\\\\%", "%")))



# mypubs$rowname<-paste("pub",nrow(mypubs),sep="_")

# bt first neeed to convert from better biblatex format

mypubs1$date <- mypubs1$year
mypubs1$journal

mypubs1 <- mypubs1 %>%
  mutate(journal = case_when(
    journal == "QUANTITATIVE SCIENCE STUDIES" ~ "Quantiative Science Studies",
    journal == "BIOTROPICA" ~ "Biotropica",
    .default = as.character(journal)
  ))
# %>%
#   mutate(category = tolower(category)) %>%
#   mutate(category = case_when(
#     category == "incollection" ~ "book chapter",
#     .default = as.character(category))) %>%
# rename(author2=author)


mypubs1$jrnl_short <- gsub(" ", "_", tolower(mypubs1$journal))


mypubs1 <- mypubs1 %>% rowid_to_column()
# mypubs1 <- mypubs1 %>% select(-rowname)
# mypubs$rowname=paste(mypubs$journal,mypubs$year,mypubs$rowid,sep="_")
mypubs1$rowname <- paste(mypubs1$jrnl_short, mypubs1$year, mypubs1$rowid, sep = "_")

# make bibtype the name of the type column (default for WriteBib)
if (has_name(mypubs1, "category") & !(has_name(mypubs1, "bibtype"))) {
  mypubs1 <- mypubs1 %>% rename(bibtype = category)
}

# read bibLATEX -----------------------------------------------------------
bibfile2 <- "./publications/better_bib_latex/EMB_publications/EMB_publications.bib"

# Import the bibtex file and convert to data.frame

mypubs2 <- bib2df(bibfile2) %>%
  remove_empty("cols") %>%
  rownames_to_column() %>% # retain rownames (as labels for bibtex re-export)
  mutate_all(funs(str_remove_all(., "[{}\"]"))) %>% ### remove {}" from bibtext entries
  mutate_all(funs(str_replace_all(., "\\\\%", "%"))) ### some replace double escaped % for markdown


names(mypubs2) <- tolower(names(mypubs2))

# bt first neeed to convert from better biblatex format
mypubs2$date <- str_split_i(mypubs2$date, "-", 1)
mypubs2$year <- mypubs2$date
mypubs2$journaltitle

mypubs2 <- mypubs2 %>%
  mutate(journaltitle = case_when(
    journaltitle == "QUANTITATIVE SCIENCE STUDIES" ~ "Quantiative Science Studies",
    journaltitle == "BIOTROPICA" ~ "Biotropica",
    .default = as.character(journaltitle)
  )) %>%
  mutate(category = tolower(category)) %>%
  mutate(category = case_when(
    category == "incollection" ~ "book chapter",
    .default = as.character(category)
  ))


mypubs2$jrnl_short <- gsub(" ", "_", tolower(mypubs2$journaltitle))


mypubs2 <- mypubs2 %>% rowid_to_column()
# mypubs$rowname=paste(mypubs$journal,mypubs$year,mypubs$rowid,sep="_")
mypubs2$rowname <- paste(mypubs2$journaltitle, mypubs2$year, mypubs2$rowid, sep = "_")

# foo<-mypubs %>% select(author, title, year) %>% mutate_all(as.character) %>% rename(author2=author)
# rownames(mypubs2) <- 1:nrow(mypubs2)
mypubs1 <- mypubs1 %>% mutate_all(as.character())
names(mypubs1)
names(mypubs2)

mypubs2<-mypubs2 %>% rename(journal=journaltitle)
mypubs1<-mypubs1 %>% rename(keywords.plus=`keywords-plus`)
glimpse(mypubs2)

mypubs1 <- mypubs1 %>%
  select(
    rowid,
    title,
    year,
    jrnl_short,
    rowname,
    bibtype,
    type,
    author,
    journal,
    volume,
    number,
    pages,
    doi,
    keywords.plus,
    keywords,
    file,
    abstract
  )



mypubs2 <- mypubs2 %>%
  select(
    rowid,
    title,
    year,
    type,
    author,
    journal,
    volume,
    number,
    pages,
    doi,
    keywords.plus,
    keywords,
    file,
    abstract,
    jrnl_short,
    rowname,
    url
  ) %>% 
  filter(title!="The Prominent Role of the Matrix in Ecology, Evolution, and Conservation")

mypubs <- full_join(mypubs1, mypubs2, by = c("title","year")) %>%
  relocate(rowid.y,.after=rowid.x) %>% 
  rename(journal=journal.x,
         # url=url.x,
         author=author.x,
         abstract=abstract.x,
         keywords=keywords.x,
         keywords.plus=`keywords.plus.x`,
         rowid=rowid.x,
         type=type.x,
         journal=journal.x,
         volume=volume.x,
         number=number.x,
         pages=pages.x,
         doi=doi.x,
         file=file.x,
         jrnl_short=jrnl_short.x,
         # bibtype=bibtype.x,
         rowname=rowname.x
         ) %>% 
  mutate(keywords.plus=tolower(keywords.plus))
  
# mypubs$author<-str_replace_all(mypubs$author,"c\\(", "")
#
# mypubs$author<-str_replace_all(mypubs$author,"\n\\)", "")
#
# mypubs$author<-str_replace_all(mypubs$author,"\n\\)", "")
#
# mypubs$author <- str_replace_all(mypubs$author, "family = ", "")
# mypubs$author <- str_replace_all(mypubs$author, "given = ", "")
# mypubs$author <- str_replace_all(mypubs$author, "prefix = ", "")
# mypubs$author <- str_replace_all(mypubs$author, "useprefix = true", "")

# make bibtype the name of the type column (default for WriteBib)
if (has_name(mypubs, "category") & !(has_name(mypubs, "bibtype"))) {
  mypubs <- mypubs %>% rename(bibtype = category)
}

# create a function which populates the md template based on the info
# about a publication
# x<-mypubs[3,]
# x<-mypubs[85,]
# x[85,]
x <- mypubs





create_qmd <- function(x) {
  #
  # foldername <- paste(x[["date"]], x[["title"]] %>%
  #                       str_replace_all(fixed(" "), "_") %>%
  #                       str_remove_all(fixed(":")) %>%
  #                       str_sub(1, 20), sep = "_")
  #
  # define a date and create filename by using the rowname for each article
  foldername <- x[["rowname"]]

  folder <- paste0(outfold, "/", foldername)
  sapply(folder, dir.create)

  # dir.create(file.path(outfold, foldername), showWarnings = TRUE)
  filename <- "index.qmd"
  # start writing
  outsubfold <- paste(outfold, foldername, sep = "/")

  if (!file.exists(file.path(outsubfold, filename)) | overwrite) {
    fileConn <- file.path(outsubfold, filename)
    write("---", fileConn)
    # write(fileConn)

    # Title
    write(paste0("title: \"", x[["title"]], "\""), fileConn, append = T)
    # Year
    write(paste0("date: \"", x[["year"]], "\""), fileConn, append = T)

    # Authors. Comma separated list, e.g. `["Bob Smith", "David Jones"]`.
    auth_hugo <- str_replace_all(x["author"], " and ", "\", \"")
    auth_hugo <- stringi::stri_trans_general(auth_hugo, "latin-ascii")
    write(paste0("author: [\"", auth_hugo, "\"]"), fileConn, append = T)

    # Journal

    # if (is.na(x[["journaltitle"]])==FALSE) {
    #   x[["journaltitle"]] <- x[["journaltitle"]]
    # } else {
    #   x[["journaltitle"]] <- x[["shortjournal"]]
    # }
    write(paste0("publication: \"", x[["journal"]], "\""), fileConn, append = T)
    # write(paste0("publication: \"", x[["journaltitle"]], "\""), fileConn, append = T)
    #
    # if (!is.na(x[["volume"]])==TRUE) {
    #   volume<-x[["volume"]]
    # } else {
    #   volume<-"volume: 'No volume'"
    # }
    #
    #
    x[is.na(x)] <- "none"

    # Volume

    x[["volume"]] <- str_replace(x[["volume"]], "n/a", "")
    # write(paste0("volume: \"", x[["volume"]], "\""), fileConn, append = T)



    if (is.na(x[["volume"]]) == FALSE) {
      write(paste0("volume: \"", x[["volume"]], "\""), fileConn, append = T)
    } else {
      write("volume: ", fileConn, append = T)
    }
    #
    #
    # Number
    if ((is.na(x[["number"]])) == FALSE) {
      write(paste0("number: \"", x[["number"]], "\""), fileConn, append = T)
    } else {
      write("number: 'No number'", fileConn, append = T)
    }

    # Pages
    x[["pages"]] <- gsub("--", "-", x[["pages"]])

    if ((is.na(x[["pages"]])) == FALSE) {
      write(paste0("pages: \"", x[["pages"]], "\""), fileConn, append = T)
    } else {
      write("pages: ", fileConn, append = T)
    }


    # DOI
    if ((is.na(x[["doi"]])) == FALSE) {
      write(paste0("doi: \"", x[["doi"]], "\""), fileConn, append = T)
    } else {
      write("doi: ", fileConn, append = T)
    }


    # Abstract and optional shortened version.
    x[["abstract"]] <- gsub("&gt;", ">", x[["abstract"]])
    x[["abstract"]] <- gsub("\\\\", "", x[["abstract"]])



    if ((is.na(x[["abstract"]])) == FALSE) {
      write(paste0("abstract: \"", x[["abstract"]], "\""), fileConn, append = T)
    } else {
      write("abstract: ", fileConn, append = T)
    }

    # Categories Comma separated list, e.g. `["term1", "term2"]`.
    # x<-x %>% re name(keywords1=keywords,
    #                 keywords2=`keywords.plus`) %>%
    #   mutate(keywords2=tolower(keywords2)) %>%
    #   relocate(keywords2,.after=keywords1)
    #
    #
    x[["keywords.plus"]] <- str_replace_all(x[["keywords.plus"]], c("[;]" = ","))
    x[["keywords.plus"]] <- tolower(x[["keywords.plus"]])
    x[["keywords.plus"]] <- str_replace_all(x[["keywords.plus"]], c("none" = ""))
    x[["keywords"]] <- tolower(x[["keywords"]])
    # x[["keywords"]] <- paste0(x[["keywords.plus"]], x[["keywords"]], sep = ",")
    x[["keywords"]] <- str_replace_all(x[["keywords"]], c("none" = ""))
    x[["keywords"]] <- str_replace_all(x[["keywords"]], c("NA," = ""))
    x[["keywords"]] <- str_replace_all(x[["keywords"]], c("NA" = ""))
    x[["keywords"]] <- str_replace_all(x[["keywords"]], c("[//*]" = ","))
    x[["keywords"]] <- str_replace_all(x[["keywords"]], "[/*]", ",")
    x[["keywords"]] <- str_replace_all(x[["keywords"]], "[:]", "-")
    # x[["keywords"]]<-str_replace_all(x[["keywords"]], "[ //n]", "")
    x[["keywords"]] <- stringi::stri_trans_general(x[["keywords"]], "latin-ascii")
    
    
    # 
    # 
    # if ((is.na(x[["keywords"]])) == TRUE) {
    #   write("categories: ", fileConn, append = T)
    # } else {
    #   write("categories: ", fileConn, append = T)
      # kw <- as.data.frame(x[["keywords"]])
      # names(kw) <- "kw"
      # cat_hugo <- kw %>% separate_longer_delim(kw, delim = ",")
      # cat_hugo$prefix <- "  - "
      # cat_hugo$kw <- paste0(cat_hugo$prefix, cat_hugo$kw, sep = "")
      # write(cat_hugo$kw, fileConn, append = T)
    # 
    if ((is.na(x[["keywords.plus"]])) == TRUE) {
      write("categories: ", fileConn, append = T)
    } else {
      write("categories: ", fileConn, append = T)
      kw <- as.data.frame(x[["keywords.plus"]])
      names(kw) <- "kw"
      cat_hugo <- kw %>% 
        separate_longer_delim(kw, delim = ",") %>% 
        filter(is.na(kw)==FALSE)
      
      cat_hugo$kw<-trimws(cat_hugo$kw)
        
      
      cat_hugo$prefix <- "  - "
      cat_hugo$kw <- paste0(cat_hugo$prefix, cat_hugo$kw, sep = "") 
      cat_hugo$kw<-sort(cat_hugo$kw)
        arrange(kw)
      write(cat_hugo$kw, fileConn, append = T)
      
      # write(paste0("categories: ", kw,""),fileConn, append = T)
      # for(i in 1:nrow(cat_hugo)) {
      #   write(cat("  - ", cat_hugo$kw[i], "\n"), fileConn, append = T)
      # }
      # write("\n", fileConn, append = T)
    }
    # write(paste0("categories: "), fileConn, append = T)
    # write(cat_hugo, fileConn, append = T)

    # write("url: ", fileConn, append = T)

    # URL
    if ((is.na(x[["url"]])) == FALSE) {
      write(paste0("url: \"", x[["url"]], "\""), fileConn, append = T)
    } else {
      write("url: \"\"", fileConn, append = T)
    }

    # Publication type. Legend:
    # 0 = Uncategorized, 1 = Conference paper, 2 = Journal article
    # 3 = Manuscript, 4 = Report, 5 = Book,  6 = Book section
    # write(paste0("category: \"", x[["category"]],"\""), fileConn, append = T)


    pdf_folder <- x[["file"]]
    pdf_folder <- as_tibble(pdf_folder)

    pdf_info <- pdf_folder %>%
      separate(value, c("value", "folder"), extra = "drop") %>%
      mutate(value = paste("./publications/articles/files", folder, "*.pdf", sep = "/")) %>%
      replace_na(list(folder = "missing"))
    pdf_folder <- as.vector(pdf_info$value)
    folder <- as.vector(pdf_info$folder)



    # write(paste0("full_citation: \"", publication,"\""), fileConn, append = T)

    # write(paste0("categories: \"", "TBD\""), fileConn, append = T)





    # Image
    write(paste0("image: featured.png"), fileConn, append = T)
    # Preprint
    write("url_preprint: \"\"", fileConn, append = T)
    # Code
    write("url_code: \"\"", fileConn, append = T)
    # Data set
    write("url_dataset: \"\"", fileConn, append = T)



    # OTHER STUFF

    # keywords<-x[["keywords"]]
    # keywords <- str_replace_all(x["keywords"], ",", "\", \"")
    # keywords <- stringi::stri_trans_general(keywords, "latin-ascii")
    # write(paste0("keywords = [\"", keywords,"\"]"), fileConn, append = T)

    # write("image_preview: \"\"", fileConn, append = T)

    # write("selected: false", fileConn, append = T)

    # write("projects = []", fileConn, append = T)

    # write("tags: []", fileConn, append = T)

    # write("url_project: \"\"", fileConn, append = T)

    # write("url_slides: \"\"", fileConn, append = T)

    # write("url_video: \"\"", fileConn, append = T)

    # write("url_poster: \"\"", fileConn, append = T)

    # write("url_source: \"\"", fileConn, append = T)

    # toc: false

    # title-block-style: none

    # write("highlight = true", fileConn, append = T)

    current.folder <-paste("./publications/better_bib_latex/EMB_publications/files/",folder,"/",sep = "")
    new.folder <- paste("./publications/articles", foldername, "", sep = "/")

    # find the files that you want
    list.of.files <- list.files(current.folder)
    new_name <- str_split(list.of.files, " - ", n = 3)
    new_name <- unlist(new_name)
    new_name <- paste(new_name[1], new_name[2])
    new_name <- gsub(" ", "_", new_name)
    new_name <- gsub("[.]", "", new_name)
    new_name <- paste(new_name, ".pdf", sep = "")
    file.rename(
      from = (paste(current.folder,
        (list.files(current.folder)),
        sep = "/"
      )),
      to = (paste(current.folder, new_name, sep = "/"))
    )

    # copy the files to the new folder
    file.copy(paste(current.folder, "/", new_name, sep = ""), new.folder)


    write(paste0("bib: './articles/", x[["rowname"]], "/cite.bib'", sep = "", collapse = "|"), fileConn, append = T)
    write(paste0("pdf: './articles/", x[["rowname"]], "/", new_name, "'", sep = "", collapse = "|"), fileConn, append = T)

    write("---", fileConn, append = T)
  }

  # convert entry back to data frame
  df_entry <- as.data.frame(as.list(x), stringsAsFactors = FALSE) %>%
    column_to_rownames("rowname")

  # write cite.bib file to outsubfolder
  WriteBib(as.BibEntry(df_entry[1, ]), paste(outsubfold, "cite.bib", sep = "/"))



  # Move the pdf files
  # identify the folders


  # '", pdf_folder,"'",sep=""),fileConn, append = T)
}

# run it ------------------------------------------------------------------
apply(mypubs, FUN = function(x) create_qmd(x), MARGIN = 1)
# }


article_folder <- "./publications/articles"
list.of.files <- list.files("./publications/articles")


for (i in seq_along(list.of.files)) {
theFiles <- paste("./publications/articles/",list.of.files[i],"/index.qmd",sep="")
pubdata<-read_lines(theFiles)
pubdata<-gsub("date:","year:",pubdata)
write_lines(pubdata,file=theFiles)
}





# # To rename the pdfs
# # directory<-"./EMB_publications/files"
# path = "./publications/articles/"
# folder_names<-list.files(path)
# file_paths<-paste(path,folder_names,sep="")
# directory<-as.data.frame(directory)
# list.files(file_paths) # only file name
# list.files(file_paths, full.names=TRUE) # full path
# old_file_names<-list.files(file_paths, full.names=TRUE) # full path


# DO I NEED THIS?
#
# # get only the ones that are pdf
# old_file_names<-Filter(function(x) str_detect(x, "pdf$"), old_file_names)
# pathsplit<-str_split(old_file_names, "/", simplify = TRUE)
# new_file_names<-paste(pathsplit[,1],pathsplit[,2],pathsplit[,3],pathsplit[,4],pathsplit[,4],sep="/")
# new_file_names<-paste(new_file_names,".pdf",sep="")
# file.rename(old_file_names,new_file_names)











#
#
#   #
#   # new_name_fcn <- function(x) {
#   #   new_name<-paste(x, list.files(x),sep="/")
#   #   return(new_name)
#   # }
#   #
#   # library(purrr)
#   # x <- nrow(directory)
#   #  <- map(1:x, paste(directory, list.files[.directory,sep="/"))
#   #
#   # file_names_new<-new_name_fcn(directory)
#   # new_name_fcn(x)<-paste(x, list.files(x),sep="/")
#   # file_names_new<-sapply(directory,new_name_fcn)
#   directory<-directory[10]
#   file_names_old<-list.files(directory)
#   file_names_new <- paste0(folder_names,".pdf")
#   file.rename(
#     paste0(directory,file_names_old,sep="/"),       # Rename files
#               paste0(directory[10], "/",file_names_new[10])
#
#   file.rename("./EMB_publications/files/3739/3739.pdf",
#               "./EMB_publications/files/3739/Araujo_etal_2013_PlantEcology.pdf")


# # option 2 ----------------------------------------------------------------
#
# #
# # NOT AS COOL
#
# # https://amirdjv.netlify.app/post/converting-bibtex-files-to-md-files/
# # https://github.com/petzi53/bib2academic
# devtools::install_github("petzi53/bib2academic")
# library(bib2academic)
# library(bibtex)
# bib2acad(bibfile = "./EMB_publications/EMB_publications.bib", copybib = TRUE, abstract = TRUE,overwrite = FALSE)
#
# bib2acad(
#   paste(
#     getwd(),
#     "./EMB_publications.bib",
#     sep = "/"),
#   copybib = TRUE, abstract = TRUE, overwrite = TRUE)
#
# bibFiles <- list.files("my-bib-folder", full.names = TRUE)
# mdFiles <- list.files("my-md-folder", full.names = TRUE)
#
#
# file.copy(from = bibFiles, to = "static/files/citations/")
# file.copy(from = mdFiles, to = "content/publication/")
#
# blogdown::serve_site()
# #
# #
# #
