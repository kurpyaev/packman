
#Использовать v8runner
#Использовать logos

Перем Лог;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
    ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Создание дистрибутива по манифесту EDF");
    // TODO - с помощью tool1cd можно получить из хранилища
    // на больших историях версий получается массивный xml дамп таблицы
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "ФайлМанифеста", "Путь к манифесту сборки");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-setup", "Собирать дистрибутив вида setup.exe");
    Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-files", "Собирать дистрибутив вида 'файлы поставки'"); 
КонецПроцедуры

// Выполняет логику команды
// 
// Параметры:
//   ПараметрыКоманды - Соответствие ключей командной строки и их значений
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
    Параметры = РазобратьПараметры(ПараметрыКоманды);
    УправлениеКонфигуратором = ОкружениеСборки.ПолучитьКонфигуратор();
    ВыполнитьСборку(УправлениеКонфигуратором, ПараметрыКоманды.ФайлМанифеста);
    
КонецФункции

Процедура ВыполнитьСборку(Знач УправлениеКонфигуратором, Знач ФайлМанифеста) Экспорт
    
    Информация = СобратьИнформациюОКонфигурации(УправлениеКонфигуратором);
    СоздатьДистрибутивПоМанифесту(УправлениеКонфигуратором, ФайлМанифеста, Информация.Версия);
    
КонецПроцедуры

Функция СобратьИнформациюОКонфигурации(Знач УправлениеКонфигуратором)
    
    Лог.Информация("Запускаю приложение для сбора информации о метаданных");
    
    ФайлДанных = Новый Файл(ОбъединитьПути(УправлениеКонфигуратором.КаталогСборки(), "v8-metadata.info"));
    Если ФайлДанных.Существует() Тогда
        УдалитьФайлы(ФайлДанных.ПолноеИмя);
    КонецЕсли;
    
    ОбработкаСборщик = Новый Файл(ПутьКОбработкеСборщикуДанных());
    Если Не ОбработкаСборщик.Существует() Тогда
        ВызватьИсключение СтрШаблон("Не обнаружена обработка сбора данных в каталоге '%1'", ОбработкаСборщик.ПолноеИмя);
    КонецЕсли;
    
    УправлениеКонфигуратором.ЗапуститьВРежимеПредприятие(ФайлДанных.ПолноеИмя, Истина, "/Execute""" + ОбработкаСборщик.ПолноеИмя + """");
    
    Возврат ПрочитатьИнформациюОМетаданных(ФайлДанных.ПолноеИмя);
    
КонецФункции

Функция ПутьКОбработкеСборщикуДанных()
    Возврат ОбъединитьПути(СтартовыйСценарий().Каталог, "../tools/СборИнформацииОМетаданных.epf");
КонецФункции

Функция ПрочитатьИнформациюОМетаданных(Знач ИмяФайла)
    
    Результат = Новый Структура();
    ЧтениеТекста = Новый ЧтениеТекста(ИмяФайла);
    Пока Истина Цикл
        Стр = ЧтениеТекста.ПрочитатьСтроку();
        Если Стр = Неопределено Тогда
            Прервать;
        КонецЕсли;
        
        Позиция = Найти(Стр, "=");
        Если Позиция = 0 Тогда
            Продолжить;
        КонецЕсли;
        
        Результат.Вставить(Лев(Стр, Позиция-1), Сред(Стр, Позиция+1));
        
    КонецЦикла;
    
    Если Не Результат.Свойство("Версия") Тогда
        ВызватьИсключение "Не найдено поле Версия в файле метаданных";
    КонецЕсли;
    
    Возврат Результат;
    
КонецФункции // ПрочитатьИнформациюОМетаданных()

Функция СоздатьДистрибутивПоМанифесту(Знач УправлениеКонфигуратором, Знач ФайлМанифеста, Знач ВерсияМетаданных)
    
    Сборщик = Новый СборщикДистрибутива;
    Сборщик.КаталогСборки = УправлениеКонфигуратором.КаталогСборки();
    Сборщик.ФайлМанифеста = ФайлМанифеста;
    
    Сборщик.Собрать(УправлениеКонфигуратором, ВерсияМетаданных, ВерсияМетаданных);
    
КонецФункции // СоздатьДистрибутивПоМанифесту(Знач УправлениеКонфигуратором, Знач ПараметрыКоманды)

Функция РазобратьПараметры(Знач ПараметрыКоманды) Экспорт
    
    Результат = Новый Структура;
    
    Если ПустаяСтрока(ПараметрыКоманды["ФайлМанифеста"]) Тогда
        ВызватьИсключение "Не задан путь к манифесту сборки (*.edf)";
    КонецЕсли;
    
    Результат.Вставить("СобиратьИнсталлятор", ПараметрыКоманды["-setup"]);
    Результат.Вставить("СобиратьФайлыПоставки", ПараметрыКоманды["-files"]);
    
    Возврат Результат;
    
КонецФункции

///////////////////////////////////////////////////////////////////////////////////

Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());