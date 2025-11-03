# ФИО: Патов Николай Андреевич
# Вариант: 21
# Условие: Описание сети аптек. Включает аптеки, лекарства, категории лекарств, провизоров, наличие и продажи лекарств.
# Аптеки: адрес, номер, ближайшая станция метро.
# Лекарства: название, дозировка, количество/объём, производитель, требуется ли рецепт, категории, цена.
# Категории: только название.
# Провизоры: ФИО, дата рождения, ИНН, паспорт, аптека.
# Наличие: аптека + лекарство + количество упаковок.
# Продажа: аптека + лекарство + провизор + дата + количество упаковок.
# Одно лекарство может принадлежать нескольким категориям.

import psycopg2
from psycopg2.errors import IntegrityError, DataError
from prettytable import PrettyTable

def get_connection():
    return psycopg2.connect(
        dbname="pharmacy",
        user="postgres",
        password="password",
        host="db"
    )

page_size = 5

def print_table(headers, data):
    headers.insert(0, 'No')
    table = PrettyTable(headers)
    for i, row in enumerate(data, 1):
        r = list(row)
        r.insert(0, i)
        table.add_row(r)
    print(table)

def list_pharmacies(conn, page=0):
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id, number, address, metro_station FROM Pharmacy ORDER BY number LIMIT %s OFFSET %s",
            (page_size, page * page_size)
        )
        rows = cur.fetchall()
    if not rows:
        print("No pharmacies found.")
        return [], []
    ids = [row[0] for row in rows]
    data = [row[1:] for row in rows]
    print_table(["Number", "Address", "Metro"], data)
    return ids, data

def list_pharmacists(conn, pharmacy_id, page=0):
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id, last_name, first_name, patronymic, birth_date, inn, passport_series, passport_number "
            "FROM Pharmacist WHERE pharmacy_id = %s ORDER BY last_name LIMIT %s OFFSET %s",
            (pharmacy_id, page_size, page * page_size)
        )
        rows = cur.fetchall()
    if not rows:
        print("No pharmacists found for this pharmacy.")
        return [], []
    ids = [row[0] for row in rows]
    data = [row[1:] for row in rows]
    print_table(["Last Name", "First Name", "Patronymic", "Birth Date", "INN", "Pass Series", "Pass Number"], data)
    return ids, data

def paginated_list(conn, list_func, select_mode=True, **kwargs):
    page = 0
    while True:
        ids, data = list_func(conn, **kwargs, page=page)
        if not ids:
            if select_mode:
                return None
            else:
                input("Press enter to continue...")
                return None
        if select_mode:
            prompt = "Enter row number (1-N), n for next, p for previous, 0 to cancel: "
        else:
            prompt = "n for next, p for previous, enter to back: "
        choice = input(prompt).strip()
        if choice == '' or choice == '0':
            return None
        elif choice.lower() == 'n':
            page += 1
            continue
        elif choice.lower() == 'p' and page > 0:
            page -= 1
            continue
        if select_mode:
            try:
                num = int(choice)
                if 1 <= num <= len(ids):
                    return ids[num - 1]
            except ValueError:
                pass
        print("Invalid input. Try again.")

def add_pharmacy(conn):
    try:
        number = int(input("Enter pharmacy number (unique integer): "))
        address = input("Enter address: ")
        metro = input("Enter nearest metro station (optional): ") or None
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO Pharmacy (number, address, metro_station) VALUES (%s, %s, %s)",
                (number, address, metro)
            )
            conn.commit()
        print("Pharmacy added successfully.")
    except (ValueError, IntegrityError, DataError) as e:
        conn.rollback()
        print(f"Error adding pharmacy: {e}")

def edit_pharmacy(conn, ph_id):
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT number, address, metro_station FROM Pharmacy WHERE id = %s", (ph_id,))
            current = cur.fetchone()
        if not current:
            print("Pharmacy not found.")
            return
        number_str = input(f"Enter new number ({current[0]}): ") or str(current[0])
        number = int(number_str)
        address = input(f"Enter new address ({current[1]}): ") or current[1]
        metro = input(f"Enter new metro ({current[2] or 'None'}): ") or current[2]
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE Pharmacy SET number = %s, address = %s, metro_station = %s WHERE id = %s",
                (number, address, metro, ph_id)
            )
            conn.commit()
        print("Pharmacy updated successfully.")
    except (ValueError, IntegrityError, DataError) as e:
        conn.rollback()
        print(f"Error updating pharmacy: {e}")

def delete_pharmacy(conn, ph_id):
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM Pharmacy WHERE id = %s", (ph_id,))
            conn.commit()
        print("Pharmacy deleted successfully.")
    except IntegrityError as e:
        conn.rollback()
        print(f"Cannot delete pharmacy (has associated records): {e}")

def add_pharmacist(conn, ph_id):
    try:
        last_name = input("Enter last name: ")
        first_name = input("Enter first name: ")
        patronymic = input("Enter patronymic (optional): ") or None
        birth_date = input("Enter birth date (YYYY-MM-DD): ")
        inn = input("Enter INN (12 characters): ")
        passport_series = input("Enter passport series (4 characters): ")
        passport_number = input("Enter passport number (6 characters): ")
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO Pharmacist (last_name, first_name, patronymic, birth_date, inn, passport_series, passport_number, pharmacy_id) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                (last_name, first_name, patronymic, birth_date, inn, passport_series, passport_number, ph_id)
            )
            conn.commit()
        print("Pharmacist added successfully.")
    except (IntegrityError, DataError) as e:
        conn.rollback()
        print(f"Error adding pharmacist: {e}")

def edit_pharmacist(conn, pharm_id):
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT last_name, first_name, patronymic, birth_date, inn, passport_series, passport_number "
                "FROM Pharmacist WHERE id = %s",
                (pharm_id,)
            )
            current = cur.fetchone()
        if not current:
            print("Pharmacist not found.")
            return
        last_name = input(f"Enter new last name ({current[0]}): ") or current[0]
        first_name = input(f"Enter new first name ({current[1]}): ") or current[1]
        patronymic = input(f"Enter new patronymic ({current[2] or 'None'}): ") or current[2]
        birth_date = input(f"Enter new birth date ({current[3]}): ") or str(current[3])
        inn = input(f"Enter new INN ({current[4]}): ") or current[4]
        passport_series = input(f"Enter new passport series ({current[5]}): ") or current[5]
        passport_number = input(f"Enter new passport number ({current[6]}): ") or current[6]
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE Pharmacist SET last_name = %s, first_name = %s, patronymic = %s, birth_date = %s, "
                "inn = %s, passport_series = %s, passport_number = %s WHERE id = %s",
                (last_name, first_name, patronymic, birth_date, inn, passport_series, passport_number, pharm_id)
            )
            conn.commit()
        print("Pharmacist updated successfully.")
    except (IntegrityError, DataError) as e:
        conn.rollback()
        print(f"Error updating pharmacist: {e}")

def delete_pharmacist(conn, pharm_id):
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM Pharmacist WHERE id = %s", (pharm_id,))
            conn.commit()
        print("Pharmacist deleted successfully.")
    except IntegrityError as e:
        conn.rollback()
        print(f"Cannot delete pharmacist (has associated records): {e}")

def manage_pharmacies(conn):
    while True:
        print("\nManage Pharmacies:")
        print("1. List pharmacies")
        print("2. Add pharmacy")
        print("3. Edit pharmacy")
        print("4. Delete pharmacy")
        print("5. Back to main menu")
        choice = input("> ").strip()
        if choice == '1':
            paginated_list(conn, list_pharmacies, select_mode=False)
        elif choice == '2':
            add_pharmacy(conn)
        elif choice == '3':
            print("Select pharmacy to edit:")
            ph_id = paginated_list(conn, list_pharmacies, select_mode=True)
            if ph_id:
                edit_pharmacy(conn, ph_id)
        elif choice == '4':
            print("Select pharmacy to delete:")
            ph_id = paginated_list(conn, list_pharmacies, select_mode=True)
            if ph_id:
                delete_pharmacy(conn, ph_id)
        elif choice == '5':
            break
        else:
            print("Invalid choice.")

def manage_pharmacists(conn):
    print("Select pharmacy to manage its pharmacists:")
    ph_id = paginated_list(conn, list_pharmacies, select_mode=True)
    if not ph_id:
        return
    while True:
        print("\nManage Pharmacists for selected pharmacy:")
        print("1. List pharmacists")
        print("2. Add pharmacist")
        print("3. Edit pharmacist")
        print("4. Delete pharmacist")
        print("5. Back to main menu")
        choice = input("> ").strip()
        if choice == '1':
            paginated_list(conn, list_pharmacists, select_mode=False, pharmacy_id=ph_id)
        elif choice == '2':
            add_pharmacist(conn, ph_id)
        elif choice == '3':
            print("Select pharmacist to edit:")
            pharm_id = paginated_list(conn, list_pharmacists, select_mode=True, pharmacy_id=ph_id)
            if pharm_id:
                edit_pharmacist(conn, pharm_id)
        elif choice == '4':
            print("Select pharmacist to delete:")
            pharm_id = paginated_list(conn, list_pharmacists, select_mode=True, pharmacy_id=ph_id)
            if pharm_id:
                delete_pharmacist(conn, pharm_id)
        elif choice == '5':
            break
        else:
            print("Invalid choice.")

def main():
    conn = get_connection()
    try:
        while True:
            print("\nMain Menu:")
            print("1. Manage Pharmacies")
            print("2. Manage Pharmacists")
            print("3. Exit")
            choice = input("> ").strip()
            if choice == '1':
                manage_pharmacies(conn)
            elif choice == '2':
                manage_pharmacists(conn)
            elif choice == '3':
                break
            else:
                print("Invalid choice.")
    finally:
        conn.close()

if __name__ == "__main__":
    main()