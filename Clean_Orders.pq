let
    // File path comes from the FilePath parameter
    FileLines = Lines.FromBinary(File.Contents(FilePath), null, null, 65001),

    // Split one line into columns
    SplitRow = (line as text) as list =>
        let
            // Remove the comma inside dates like "Sep 5, 2025"
            NoDateComma = Text.Replace(line, ", 2025", " 2025"),
            // Replace every delimiter with "|"
            OneDelimiter = Text.Replace(Text.Replace(Text.Replace(Text.Replace(NoDateComma, "#(tab)", "|"), ";", "|"), " - ", "|"), ",", "|"),
            Parts = List.Transform(Text.Split(OneDelimiter, "|"), Text.Trim)
        in
            // Some rows have only 5 values (date and status are missing)
            if List.Count(Parts) = 5
            then List.Combine({List.FirstN(Parts, 4), {null, null}, {Parts{4}}})
            else Parts,

    RawTable = Table.FromRows(
        List.Transform(FileLines, SplitRow),
        {"OrderID", "Customer", "Phone", "City", "OrderDate", "Status", "Amount"}),

    // Keep digits only and make the phone start with 0 (01xxxxxxxxx)
    CleanPhone = (phone as nullable text) as nullable text =>
        if phone = null or phone = "N/A" then null else
        let
            Digits = Text.Select(phone, {"0".."9"}),
            NoCountryCode =
                if Text.StartsWith(Digits, "0020") then Text.Range(Digits, 4)
                else if Text.StartsWith(Digits, "20") then Text.Range(Digits, 2)
                else Digits
        in
            if Text.StartsWith(NoCountryCode, "0") then NoCountryCode else "0" & NoCountryCode,

    // Different spellings of the same city -> one correct spelling
    CityLookup = {
        {"الأسكندرية", "الإسكندرية"}, {"Alexandria", "الإسكندرية"},
        {"القاهره", "القاهرة"},       {"Cairo", "القاهرة"},
        {"جيزة", "الجيزة"},           {"Giza", "الجيزة"}
    },
    FixCity = (city as text) as text =>
        let Match = List.First(List.Select(CityLookup, each _{0} = city), null)
        in if Match = null then city else Match{1},

    // Dates come in 4 formats: dd/MM/yyyy, yyyy.MM.dd, yyyy-MM-dd, "Sep 5 2025"
    ParseOrderDate = (text_date as nullable text) as nullable date =>
        if text_date = null then null
        else if Text.Contains(text_date, "/") then Date.FromText(text_date, [Format = "dd/MM/yyyy", Culture = "en-US"])
        else if Text.Contains(text_date, ".") then Date.FromText(Text.Replace(text_date, ".", "-"), [Format = "yyyy-MM-dd", Culture = "en-US"])
        else if Text.Contains(text_date, "-") then Date.FromText(text_date, [Format = "yyyy-MM-dd", Culture = "en-US"])
        else Date.FromText(text_date, [Format = "MMM d yyyy", Culture = "en-US"]),

    CleanedTable = Table.TransformColumns(RawTable, {
        {"OrderID",   Text.Trim, type text},
        {"Customer",  Text.Trim, type text},
        {"Phone",     CleanPhone, type text},
        {"City",      FixCity, type text},
        {"OrderDate", ParseOrderDate, type date},
        {"Status",    each if _ = null then null else Text.Proper(_), type text},
        {"Amount",    each Number.From(Text.Trim(Text.Replace(_, "EGP", ""))), Int64.Type}
    }),

    FinalTable = Table.RenameColumns(CleanedTable, {{"Amount", "Amount_EGP"}}),
    #"Filtered Rows" = Table.SelectRows(FinalTable, each ([Status] <> null))
in
    #"Filtered Rows"
